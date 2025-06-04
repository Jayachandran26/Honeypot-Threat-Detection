#!/usr/bin/env python3
"""
Real-time Cowrie log parser and API server
Parses Cowrie JSON logs and provides REST API for dashboard
"""

import json
import time
import threading
from datetime import datetime
from collections import defaultdict, deque
from flask import Flask, jsonify, request
from flask_cors import CORS
import requests
import geoip2.database
import geoip2.errors

app = Flask(__name__)
CORS(app)

class CowrieLogParser:
    def __init__(self, log_file='/home/cowrie/cowrie/var/log/cowrie/cowrie.json'):
        self.log_file = log_file
        self.events = deque(maxlen=1000)  # Keep last 1000 events
        self.stats = {
            'total_attempts': 0,
            'unique_ips': set(),
            'active_sessions': set(),
            'countries': defaultdict(int),
            'commands': defaultdict(int),
            'credentials': defaultdict(int)
        }
        self.running = False
        
        # Try to load GeoIP database
        try:
            self.geoip_reader = geoip2.database.Reader('/usr/share/GeoIP/GeoLite2-Country.mmdb')
        except:
            self.geoip_reader = None
            print("GeoIP database not found. Install with: sudo apt install geoip-database-extra")

    def get_country(self, ip):
        """Get country from IP address"""
        if not self.geoip_reader:
            return "Unknown"
        
        try:
            response = self.geoip_reader.country(ip)
            return response.country.name
        except geoip2.errors.AddressNotFoundError:
            return "Unknown"
        except:
            return "Unknown"

    def parse_log_line(self, line):
        """Parse a single log line"""
        try:
            data = json.loads(line.strip())
            
            # Extract relevant information
            event = {
                'id': f"{data.get('session', '')}-{data.get('timestamp', '')}",
                'timestamp': data.get('timestamp', ''),
                'source_ip': data.get('src_ip', ''),
                'session': data.get('session', ''),
                'event_type': data.get('eventid', ''),
                'message': data.get('message', ''),
                'username': data.get('username', ''),
                'password': data.get('password', ''),
                'command': data.get('input', ''),
                'country': self.get_country(data.get('src_ip', '')),
                'severity': self.determine_severity(data)
            }
            
            # Update statistics
            self.update_stats(event, data)
            
            # Add to events queue
            self.events.appendleft(event)
            
            return event
            
        except json.JSONDecodeError:
            return None
        except Exception as e:
            print(f"Error parsing log line: {e}")
            return None

    def determine_severity(self, data):
        """Determine event severity based on content"""
        high_risk_commands = ['wget', 'curl', 'chmod', 'rm -rf', 'dd if=', 'mkfs']
        medium_risk_events = ['cowrie.command.success', 'cowrie.session.file_download']
        
        if data.get('eventid') in medium_risk_events:
            return 'medium'
        
        command = data.get('input', '').lower()
        if any(cmd in command for cmd in high_risk_commands):
            return 'high'
        
        if data.get('eventid') == 'cowrie.login.failed':
            return 'low'
        
        return 'medium'

    def update_stats(self, event, raw_data):
        """Update statistics"""
        if event['source_ip']:
            self.stats['unique_ips'].add(event['source_ip'])
        
        if event['session']:
            self.stats['active_sessions'].add(event['session'])
        
        if event['country']:
            self.stats['countries'][event['country']] += 1
        
        if event['command']:
            self.stats['commands'][event['command']] += 1
        
        if event['username'] and event['password']:
            cred = f"{event['username']}:{event['password']}"
            self.stats['credentials'][cred] += 1
        
        self.stats['total_attempts'] += 1

    def tail_log_file(self):
        """Tail the log file for new entries"""
        try:
            with open(self.log_file, 'r') as f:
                # Go to end of file
                f.seek(0, 2)
                
                while self.running:
                    line = f.readline()
                    if line:
                        event = self.parse_log_line(line)
                        if event:
                            print(f"New event: {event['event_type']} from {event['source_ip']}")
                    else:
                        time.sleep(0.1)
                        
        except FileNotFoundError:
            print(f"Log file not found: {self.log_file}")
        except Exception as e:
            print(f"Error reading log file: {e}")

    def start_monitoring(self):
        """Start monitoring log file"""
        self.running = True
        thread = threading.Thread(target=self.tail_log_file)
        thread.daemon = True
        thread.start()
        print("Started log monitoring...")

    def stop_monitoring(self):
        """Stop monitoring"""
        self.running = False

# Initialize parser
parser = CowrieLogParser()

@app.route('/api/events')
def get_events():
    """Get recent events"""
    limit = request.args.get('limit', 50, type=int)
    events_list = list(parser.events)[:limit]
    return jsonify(events_list)

@app.route('/api/stats')
def get_stats():
    """Get current statistics"""
    stats = {
        'total_attempts': parser.stats['total_attempts'],
        'unique_ips': len(parser.stats['unique_ips']),
        'active_sessions': len(parser.stats['active_sessions']),
        'top_countries': sorted(
            [{'country': k, 'count': v} for k, v in parser.stats['countries'].items()],
            key=lambda x: x['count'],
            reverse=True
        )[:10],
        'top_commands': sorted(
            [{'command': k, 'count': v} for k, v in parser.stats['commands'].items()],
            key=lambda x: x['count'],
            reverse=True
        )[:10],
        'top_credentials': sorted(
            [{'credential': k, 'count': v} for k, v in parser.stats['credentials'].items()],
            key=lambda x: x['count'],
            reverse=True
        )[:10]
    }
    return jsonify(stats)

@app.route('/api/health')
def health_check():
    """Health check endpoint"""
    return jsonify({
        'status': 'healthy',
        'monitoring': parser.running,
        'events_count': len(parser.events),
        'timestamp': datetime.now().isoformat()
    })

if __name__ == '__main__':
    # Start log monitoring
    parser.start_monitoring()
    
    # Start Flask app
    print("Starting Cowrie Dashboard API server...")
    print("API available at: http://localhost:5000")
    app.run(host='0.0.0.0', port=5000, debug=True)

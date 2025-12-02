from flask import Flask, request, jsonify

app = Flask(__name__)

# In-memory vote storage
votes = {
    'a': 0,
    'b': 0
}

@app.route('/')
def index():
    return jsonify({
        'service': 'voting',
        'status': 'ok',
        'message': 'Voting service is running'
    })

@app.route('/vote', methods=['POST'])
def vote():
    """
    Accept votes for options 'a' or 'b'
    Request body: {"option": "a"} or {"option": "b"}
    """
    data = request.get_json()
    
    if not data or 'option' not in data:
        return jsonify({'error': 'Missing option in request'}), 400
    
    option = data['option'].lower()
    
    if option not in ['a', 'b']:
        return jsonify({'error': 'Invalid option. Must be "a" or "b"'}), 400
    
    votes[option] += 1
    
    return jsonify({
        'status': 'success',
        'option': option,
        'current_count': votes[option]
    }), 200

@app.route('/results', methods=['GET'])
def results():
    """
    Get current vote results with counts and percentages
    """
    total = votes['a'] + votes['b']
    
    percentage_a = (votes['a'] / total * 100) if total > 0 else 0
    percentage_b = (votes['b'] / total * 100) if total > 0 else 0
    
    return jsonify({
        'votes': votes,
        'total': total,
        'percentages': {
            'a': round(percentage_a, 2),
            'b': round(percentage_b, 2)
        }
    })

@app.route('/health', methods=['GET'])
def health():
    """Health check endpoint"""
    return jsonify({'healthy': True}), 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=False)

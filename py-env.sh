# Install venv if missing
apt update && apt install -y python3-venv

# Create a virtual environment
python3 -m venv venv

# Activate it
source venv/bin/activate

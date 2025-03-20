import pyshark
import sys
import binascii
import urllib.parse 

def extract_query_param(uri):
    """
    Extracts the value of the 'query' parameter from the given URI.
    """
    param_key = "query="
    start_index = uri.find(param_key)
    
    if start_index == -1:
        return None  # 'query=' not found in the URI

    # Move the index to start after 'query='
    start_index += len(param_key)

    # Find the end of the query value (either '&' or end of string)
    end_index = uri.find("&", start_index)
    
    if end_index == -1:  # No '&' found, take until end of string
        return uri[start_index:]
    else:
        return uri[start_index:end_index]

def hex_to_ascii(hex_data):
    """
    Converts hex-encoded response data into ASCII text.
    """
    try:
        return binascii.unhexlify(hex_data.replace(':', '')).decode('utf-8', errors='ignore')
    except Exception as e:
        return f"[Error decoding response: {e}]"

def extract_http_data(packet):
    """ Extract HTTP response body from a packet if available. """
    try:
        if 'HTTP' in packet and hasattr(packet.http, 'file_data'):
            hex_data = packet.http.file_data.replace(':', '')  # Remove colons if present
            return hex_to_ascii(hex_data)
    except AttributeError:
        pass
    return None

def check_and_extract_sql_parts(query, user):
    """
    Checks if the query matches the format:
    '1 AND ORD(MID((SELECT IFNULL(CAST(`description` AS NCHAR),0x20) FROM profile_db.`profiles` ORDER BY id LIMIT 0,1),42,1))>96'
    and extracts `description` and 42
    """
    required_prefix = "1 AND ORD(MID((SELECT IFNULL(CAST(`"
    
    # Ensure query starts correctly
    if not query.startswith(required_prefix):
        return None
    
    # Find the field name (e.g., 'description')
    start_index = len(required_prefix)
    end_index = query.find("`", start_index)
    
    if end_index == -1:
        return None  # Incorrect format
    
    field_name = query[start_index:end_index]

    # Ensure correct suffix structure
    if(field_name == 'name') :
        after_field = "` AS NCHAR),0x20) FROM profile_db.`profiles` ORDER BY id LIMIT " + str(user) + ",1)"
        after_field_start = end_index + len("` AS NCHAR),0x20) FROM profile_db.`profiles` ORDER BY id LIMIT " + str(user) + ",1)")
    
    if(field_name == 'description') :
        after_field = "` AS NCHAR),0x20) FROM profile_db.`profiles` ORDER BY id LIMIT " + str(user) + ",1)"
        after_field_start = end_index + len("` AS NCHAR),0x20) FROM profile_db.`profiles` ORDER BY id LIMIT " + str(user) + ",1)")
    
    if not query.startswith(after_field, end_index):
        return None  # Incorrect format
    
    # Find the LIMIT number
    after_limit = query[after_field_start:]
    comma_index = after_limit.find(",")
    if comma_index == -1:
        return None  # Incorrect format
        
    limit_value = after_limit[:comma_index]  # Extract LIMIT value
    after_limit = after_limit[comma_index+1:]  # Move to next value
    
    # Find the MID position value
    mid_end_index = after_limit.find(",1))>")  # Looking for ",1))>"
    end_index = mid_end_index + 5
    
    if mid_end_index == -1:
        return None  # Incorrect format
        
    mid_position_str = after_limit[:mid_end_index] 
    try:
        mid_position = int(mid_position_str)  # Convert to integer
    except ValueError:
        return None  # Not a valid number

    end_position_str = after_limit[end_index:]
    try:
        end_position = int(end_position_str)  # Convert to integer
    except ValueError:
        return None  # Not a valid number
    
    
    return field_name, mid_position, end_position  # Return extracted values

def parse_pcapng(file_path, user):
    """ Parses the given pcapng file and extracts query values and their responses. """
    cap = pyshark.FileCapture(file_path, display_filter="http")

    queries_responses = {}
    results = {}

    for packet in cap:
        try:
            if hasattr(packet, 'http'):
                # Check if it's a GET request with the target URL pattern
                if hasattr(packet.http, 'request_uri'):
                    uri = packet.http.request_uri
                    if "/search_app/search.php?" in uri:  # Ensure it's the correct endpoint
                        query_value = extract_query_param(uri)

                        if query_value:
                            # Extract response payload
                            response_data = extract_http_data(packet)
                            decoded_query = urllib.parse.unquote(query_value)

                            # Store results
                            queries_responses[decoded_query] = response_data
                            result = check_and_extract_sql_parts(decoded_query, user)
                            
                            if(result is not None and response_data) : 
                                field, rank, value = result
                                if not field in results : results[field] = [0 for _ in range(200)]
                                if (response_data.find("Void:") != -1) :
                                    if results[field][rank - 1] < value : results[field][rank - 1] = value
                 

        except Exception as e:
            print(f"Error processing packet: {e}")

    for key in results:
        string = ''.join(chr(i + 1) for i in results[key])
        print(f"{user} : {key} = {string}")                                                               
     
    cap.close()
    return queries_responses

if __name__ == "__main__":
    # Check if a filename is provided
    if len(sys.argv) != 3:
        print(f"Usage: python3 {sys.argv[0]} mypcapng.pcapng user")
        sys.exit(1)

    pcapng_file = sys.argv[1]
    user = sys.argv[2]
    results = parse_pcapng(pcapng_file, user)

    # If needed, you can process 'results' further

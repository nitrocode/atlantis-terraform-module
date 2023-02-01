package backend

import future.keywords

test_allow_correct_backend if {
	allow with input as {"terraform": [{"backend": {"s3": [{
		"bucket": "bucket",
		"key": "key",
		"region": "us-east-1",
	}]}}]}
}

test_deny_missing_region if {
	not allow with input as {"terraform": [{"backend": {"s3": [{
		"bucket": "bucket",
		"key": "key",
	}]}}]}
}

test_deny_missing_key if {
	not allow with input as {"terraform": [{"backend": {"s3": [{
		"bucket": "bucket",
		"region": "us-east-1",
	}]}}]}
}

test_deny_missing_bucket if {
	not allow with input as {"terraform": [{"backend": {"s3": [{
		"region": "us-east-1",
		"key": "key",
	}]}}]}
}

test_deny_missing_backend if {
	not allow with input as {"terraform": [{}]}
}

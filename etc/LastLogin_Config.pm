Set( $LastLogin_CustomFieldName, 'Last Login' );

# 1 = record a transaction on the user for every login (visible in the
# user's history); 0 = update the custom field value only.
Set( $LastLogin_RecordTransaction, 0 );

# Minimum seconds between two recorded updates for the same user; 0 = always
# update. Raise this if login frequency ever makes the extra write load
# noticeable.
Set( $LastLogin_MinInterval, 0 );

1;

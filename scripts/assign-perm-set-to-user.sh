USER_ALIAS="${USER_ALIAS:-sfdx-privacy-center-compliance__dev}"
#USER_ALIAS="${USER_ALIAS:-sfdx-privacy-center-compliance__qa}"
# perm set 1
PERM_SET=RC_Privacy_Center_Compliance
echo assigning permission set $PERM_SET to USER_ALIAS = $USER_ALIAS
sfdx force:user:permset:assign -n $PERM_SET -u $USER_ALIAS
!#/bin/bash

# date 2017-01-23 

proxy_user=admin
proxy_pwd=admin
proxy_port=6032
proxy_host=127.0.0.1

username=devel

which mysqladmin >/dev/null 2>&1
if [ $? -ne 0 ]
then
  echo "mysql client is not found in path, please install..."
  exit 2
fi


if [ $# -eq 0 ]
then
  echo "$0 requires options:" 
  echo "                     -c to specify a column," 
  echo "                     -t to specify a table where select * is not allowed"
  exit 1
fi

while getopts ":c:t:" opt
do
  case $opt in
   c)
      echo "column: $OPTARG"
      COLUMN=$OPTARG
      ;;
   t) 
      echo "table: $OPTARG"
      TABLE=$OPTARG
      ;;
   \?)
      echo "Invalid option: -$OPTARG"
      exit 1
      ;;
   :)
      echo "Option -$OPTARG requires an argument."
      exit 1
      ;;
   esac
done

#check the column rules
if [ "$COLUMN" != "" ]
then
  # we don't perform check (yet) so watchout for duplicates
  mysql -BN -u ${proxy_user} -p${proxy_pwd} -h ${proxy_host} -P${proxy_port} \
  -e "INSERT INTO mysql_query_rules 
      (active,username,match_pattern,replace_pattern,apply,re_modifiers)  
      VALUES 
      (1,'${username}','\`*${COLUMN}*\`','${COLUMN}',0,'caseless,global'),
      (1,'${username}','(\(?)(\`?\w+\`?\.)?${COLUMN}(\)?)([ ,\n])',\"\1CONCAT(LEFT(\2${COLUMN},2),REPEAT('X',10))\3 ${COLUMN}\4\",0,'caseless,global'),
      (1,'${username}','\)(\)?) ${COLUMN}\s+(\w),',')\1 \2,',1,'caseless,global'),
      (1,'${username}','\)(\)?) ${COLUMN}\s+(.*)\s+from',')\1 \2 from',1,'caseless,global');"
  
fi

# check if we need to add a rule to avoid select * in a table
if [ "$TABLE" != "" ]
then
   # connect to proxysql and check is a rule already exists
   echo $(mysql -BN -u ${proxy_user} -p${proxy_pwd} -h ${proxy_host} -P${proxy_port} \
   -e "select rule_id,active from mysql_query_rules where match_pattern like '^SELECT \*.*FROM.*${TABLE}';" 2>/dev/null) | while read rule_id active
   do
      if [ "$rule_id" != "" ]
      then
         echo -n "there is already a rule : rule_id = $rule_id "
         if [ "$active" == "1" ]  
         then
           echo "[active]"
         else
           echo "[inactive]"
           # we need to activate it
           mysql -BN -u ${proxy_user} -p${proxy_pwd} -h ${proxy_host} -P${proxy_port} \
           -e "update mysql_query_rules set active=1 where rule_id=$rule_id"
         fi
      else
         echo "let's add the rules..."
         mysql -BN -u ${proxy_user} -p${proxy_pwd} -h ${proxy_host} -P${proxy_port} \
           -e "INSERT INTO mysql_query_rules (active,username,match_pattern,error_msg,re_modifiers)
               VALUES (1,'${username}','^SELECT\s+\*.*FROM.*${TABLE}', 
               'Query not allowed due to sensitive information, please contact dba@myapp.com','caseless,global' );"
         mysql -BN -u ${proxy_user} -p${proxy_pwd} -h ${proxy_host} -P${proxy_port} \
           -e "INSERT INTO mysql_query_rules (active,username,match_pattern,error_msg,re_modifiers)
               VALUES (1,'${username}','^SELECT\s+${TABLE}\.\*.*FROM.*${TABLE}', 
               'Query not allowed due to sensitive information, please contact dba@myapp.com','caseless,global' );"
         mysql -BN -u ${proxy_user} -p${proxy_pwd} -h ${proxy_host} -P${proxy_port} \
           -e "INSERT INTO mysql_query_rules (active,username,match_pattern,error_msg,re_modifiers)
               VALUES (1,'${username}','^SELECT\s+(\w+)\.\*.*FROM.*${TABLE}\s+(as\s+)?(\1)', 
               'Query not allowed due to sensitive information, please contact dba@myapp.com','caseless,global' );"
      fi 
   done
fi

mysql -BN -u ${proxy_user} -p${proxy_pwd} -h ${proxy_host} -P${proxy_port} \
-e "set mysql-query_processor_regex=1; load mysql variables to runtime; load mysql query rules to runtime;"

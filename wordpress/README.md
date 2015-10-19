ATLO/wordpress container
========================

Configuration of worpress via etcd
----------------------------------

Configuration for Worpress must be provided in etcd acording to the following structure of keys and values:

- prefrix
 	- wordpress_conf:
 		- wp-admin: name of the user to create as wp-admin  [ Mandatory ]
 		- wp-admin-pw: crypt password for the wp-admin user [ Mandatory ]
 		- mysql-type: **"static" | "dynamic"** [ Mandatory ]
 		  
 		  **static**: will configure mysql mysql access of wordpress with the information provided using mysql-static-ip, mysql-static-port,mysql-static-user,mysql-static-pwd keys in this etcd directory.
 		  
 		  **dynamic**: will use the value of mysq-dynamic as key for retrieving values of credentials or dynamic addressess compatible with atlo/mysql container. This setting works properly if alto/mysql container is being executed as fleet service as ip addresses and ports are provided by the mysql-sk@.service unit. 
 		  
 		- mysql-static-ip: ip or addresss of mysql when mysql-type=static [ default: host_ip ]
 		- mysql-static-port: port of mysql of mysql when mysql-type=static [ default: 3360 ]
 		- mysql-static-db: Name of db to store wordpress data [Mandatory]
 		- mysql-static-user: user for mysql when mysql-type=static         [ Mandatory ]
 		- mysql-static-pwd:  cryt password of mysql [ Mandatory ]

 		- mysql-dynamic-key: full path of etcd key with mysql configuration parameters [ Mandatory]
 		- mysql-dynamic-ip-pattern: TBD [ default: mysql-1-ip ]
 		- mysql-dynamic-port-pattern: TBD [default: mysql-1-port ]

 	- nginx:
 		- 	conf:
 			-  worker_processes: 	number of worker processess for nginx [ Mandatory ]
 			-  worker_connection:	number or connections per worker [ Mandatory ]
 			-  sites:
 				- site-wordpress:
 					- domain: domain applicable to the wordpress site. 
 					- listen: ports to listen.
 					
  
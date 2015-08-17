# OpenAM Enterprise Subscription Docker image
# Version 1

# If you loaded redhat-rhel-server-7.0-x86_64 to your local registry, uncomment
# this FROM line instead:
# FROM registry.access.redhat.com/rhel 
# Pull the rhel image from the local repository
FROM conductdocker/rhel7

MAINTAINER Kim Daniel Engebretsen 

# Update image
#RUN yum update -y
#RUN yum install -y unzip openssl java-1.7.0-openjdk #-devel # java-1.7.0-oracle-devel
#RUN yum clean all

ENV OPENDJ_HOME /opt/opendj
ENV OPENDJ_JAVA_HOME /usr/lib/jvm/jre
ENV ADMIN_PW Secret1
ENV KEYSTORE_PW Secret1

# Create an index.html file
RUN mkdir -p /opt/opendj/docker-config
ADD opendj-setup.properties /opt/opendj/docker-config/opendj-setup.properties
ADD base_dn.ldif /opt/opendj/docker-config/base_dn.ldif
ADD keystore.jceks /opt/opendj/docker-config/keystore.jceks


ADD OpenDJ-2.6.3.zip /tmp/OpenDJ-2.6.3.zip
RUN cd /opt; unzip /tmp/OpenDJ-2.6.3.zip
WORKDIR /opt/opendj

EXPOSE 8080 1636 1389 4444
RUN /opt/opendj/setup -i -n -Q --acceptLicense --doNotStart --propertiesFilePath /opt/opendj/docker-config/opendj-setup.properties; \
echo -e "\nOpenDJ setup script complete\n"; 

ADD opendj_user_schema.ldif /opt/opendj/docker-config/opendj_user_schema.ldif
ADD cts-add-schema.ldif /opt/opendj/docker-config/cts-add-schema.ldif
ADD add-config-entries.ldif /opt/opendj/docker-config/add-config-entries.ldif

RUN /opt/opendj/bin/start-ds; \  
/opt/opendj/bin/dsconfig -D 'cn=Directory Manager' -w "$ADMIN_PW" -p 4444 -X -n --advanced set-global-configuration-prop --set single-structural-objectclass-behavior:accept;\ 
/opt/opendj/bin/ldapmodify \
  --port 1389 \
  --bindDN "cn=Directory Manager" \
  --bindPassword "$ADMIN_PW" \
  --defaultAdd \
  --useStartTLS \
  --trustAll \
  --filename /opt/opendj/docker-config/opendj_user_schema.ldif;\
/opt/opendj/bin/ldapmodify \
  --port 1389 \
  --bindDN "cn=Directory Manager" \
  --bindPassword "$ADMIN_PW" \
  --useStartTLS \
  --trustAll \
  --fileName /opt/opendj/docker-config/cts-add-schema.ldif; \
/opt/opendj/bin/dsconfig create-backend --backend-name cfgStore --set base-dn:dc=openam,dc=no --set enabled:true --type local-db --port 4444 --bindDN "cn=Directory Manager" --bindPassword "$ADMIN_PW" --no-prompt;\ 
/opt/opendj/bin/ldapmodify \
  --port 1389 \
  --bindDN "cn=Directory Manager" \
  --bindPassword "$ADMIN_PW" \
  --defaultAdd \
  --useStartTLS \
  --trustAll \
  --filename /opt/opendj/docker-config/add-config-entries.ldif; \
/opt/opendj/bin/dsconfig \
   set-access-control-handler-prop \
    --add global-aci:'(target = "ldap:///cn=schema")(targetattr = "attributeTypes || \
      objectClasses")(version 3.0; acl "Modify schema"; allow (write) \
      (userdn = "ldap:///uid=openam,ou=admins,dc=openam,dc=no");)' \
    --port 4444 \
    --bindDN "cn=Directory Manager" \
    --bindPassword "$ADMIN_PW" \
    --trustAll \
    --no-prompt; \
/opt/opendj/bin/dsconfig \
   create-local-db-index \
   --port 4444 \
   --bindDN "cn=Directory Manager" \
   --bindPassword "$ADMIN_PW" \
   --backend-name cfgStore \
   --index-name iplanet-am-user-federation-info-key \
   --set index-type:equality \
   --trustAll \
   --no-prompt; \
/opt/opendj/bin/dsconfig \
   create-local-db-index \
   --port 4444 \
   --bindDN "cn=Directory Manager" \
   --bindPassword "$ADMIN_PW" \
   --backend-name cfgStore \
   --index-name sun-fm-saml2-nameid-infokey \
   --set index-type:equality \
   --trustAll \
   --no-prompt; \
#/opt/opendj/bin/dsconfig \
#   create-local-db-index \
#   --port 4444 \
#   --bindDN "cn=Directory Manager" \
#   --bindPassword "$ADMIN_PW" \
#   --backend-name cfgStore \
#   --index-name sunxmlkeyvalue \
#   --set index-type:"equality" \
#   --set index-type:"substring" \
#   --trustAll \
#   --no-prompt; \
/opt/opendj/bin/rebuild-index --port 4444 \
  --bindDN "cn=Directory Manager" --bindPassword "$ADMIN_PW" \
  --baseDN dc=openam,dc=no --rebuildAll \
  --start 0 \
  --trustAll; \
/opt/opendj/bin/verify-index --baseDN dc=openam,dc=no;
     


CMD ["/opt/opendj/bin/start-ds", "-N"]
#ENTRYPOINT ["/bin/bash"]

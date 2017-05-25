
# s2i-apb-builder
FROM centos:7
MAINTAINER Ansible Playbook Bundle Community

LABEL "com.redhat.apb.version"="0.1.0"

LABEL io.openshift.s2i.scripts-url=image:///usr/libexec/s2i
LABEL io.openshift.s2i.destination=/tmp

COPY ./s2i/bin/ /usr/libexec/s2i

ENV USER_NAME=apb \
    USER_UID=1001 \
    BASE_DIR=/opt/apb
ENV HOME=${BASE_DIR}

RUN mkdir -p /root/.kube /usr/share/ansible/openshift \
             /etc/ansible /opt/ansible \
             /opt/ansible/roles \
             ${BASE_DIR} ${BASE_DIR}/etc \
             ${BASE_DIR}/actions \
             ${BASE_DIR}/.kube ${BASE_DIR}/.ansible/tmp && \
             useradd -u ${USER_UID} -r -g 0 -M -d ${BASE_DIR} -b ${BASE_DIR} -s /sbin/nologin -c "apb user" ${USER_NAME} && \
             chown -R ${USER_NAME}:0 /opt/{ansible,apb} && \
             chmod -R g+rw /opt/{ansible,apb} ${BASE_DIR} /etc/passwd

COPY config /root/.kube/config

RUN curl https://copr.fedorainfracloud.org/coprs/jmontleon/asb/repo/epel-7/jmontleon-asb-epel-7.repo -o /etc/yum.repos.d/asb.repo
RUN yum -y install epel-release centos-release-openshift-origin \
    && yum -y update \
    && yum -y install origin-clients python-openshift ansible ansible-kubernetes-modules pwgen \
    yum -y install python-boto postgresql \
    && yum clean all

RUN echo "localhost ansible_connection=local" > /etc/ansible/hosts \
    && echo '[defaults]' > /etc/ansible/ansible.cfg \
    && echo 'roles_path = /etc/ansible/roles:/opt/ansible/roles' >> /etc/ansible/ansible.cfg

COPY oc-login.sh entrypoint.sh /usr/bin/

USER ${USER_UID}
RUN sed "s@${USER_NAME}:x:${USER_UID}:@${USER_NAME}:x:\${USER_ID}:@g" /etc/passwd > ${BASE_DIR}/etc/passwd.template

CMD ["usage"]

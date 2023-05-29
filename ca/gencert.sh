#!/bin/sh

base_name="${0##*/}"
runtime_directory=$(
  cd "$(dirname "$0")" || exit 1
  pwd
)

usage() {
  printf "Usage: %s\n \
    -t <Specify the cert type, such as ca, server, client \n \
    -o <Specify the output directory, default ./cert \n \
    -c <Specify the ca directory when generating server or client certificate \n \
    -d <Specify the domain name, such as yeying.pub or odsn.pub and so on \n \
    " "${base_name}"
  exit 1
}

if [ $# -eq 0 ]; then
  usage
fi

# For macos`s getopt, reference: https://formulae.brew.sh/formula/gnu-getopt
while getopts ":t:d:o:c" o; do
  case "${o}" in
  d)
    domain=${OPTARG}
    ;;
  t)
    type=${OPTARG}
    ;;
  o)
    output=${OPTARG}
    ;;
  c)
    ca_dir=${OPTARG}
    ;;
  *)
    usage
    ;;
  esac
done
shift $((OPTIND - 1))

if [ -z "${type}" ]; then
  echo "Please specify the cert type to generate!"
  usage
fi

if [ -z "${domain}" ]; then
  echo "Please specify the domain name to generate!"
  usage
fi

if [ -z "${output}" ]; then
  output="${runtime_directory}/cert"
fi

if [ -z "${ca_dir}" ]; then
  ca_dir="${runtime_directory}/cert"
fi

mkdir -p "${output}"

if [ "${type}" == "ca" ]; then
  echo "1. Generate CA's private key and self-signed certificate"
  rm "${output}"/ca-*.pem
  ca_cert="${output}"/ca-cert.pem
  ca_key="${output}"/ca-key.pem

  openssl req -x509 -newkey rsa:4096 -sha256 -days 365 -nodes \
    -keyout "${ca_key}" \
    -out "${ca_cert}" \
    -subj "/C=CN/ST=NanJing/L=China/O=YeYing/OU=Community/CN=*.${domain}/emailAddress=community.yeying@gmail.com"

  echo "CA's self-signed certificate"
  openssl x509 -in "${ca_cert}" -noout -text
elif [ "${type}" == "server" ]; then
  echo "2. Generate web server's private key and certificate signing request (CSR)"
  ca_cert="${ca_dir}"/ca-cert.pem
  ca_key="${ca_dir}"/ca-key.pem

  rm "${output}"/server-*.pem
  server_key="${output}"/server-key.pem
  server_req="${output}"/server-req.pem
  openssl req -newkey rsa:4096 -sha256 -nodes \
    -keyout "${server_key}" \
    -out "${server_req}" \
    -subj "/C=CN/ST=NanJing/L=China/O=YeYing/OU=Application/CN=*.${domain}/emailAddress=community.yeying@gmail.com"

  # Use CA's private key to sign web server's CSR and get back the signed certificate
  server_cert="${output}"/server-cert.pem
  server_ext="${output}"/server-ext.cnf
  echo "subjectAltName=DNS:*.${domain},DNS:localhost,IP:0.0.0.0" >"${server_ext}"
  openssl x509 -req -in "${server_req}" -days 60 -CA "${ca_cert}" -CAkey "${ca_key}" -CAcreateserial \
    -out "${server_cert}" \
    -extfile "${server_ext}"

  echo "Server's signed certificate"
  openssl x509 -in "${server_cert}" -noout -text
elif [ "${type}" == "client" ]; then
  echo "3. Generate client's private key and certificate signing request (CSR)"
  ca_cert="${ca_dir}"/ca-cert.pem
  ca_key="${ca_dir}"/ca-key.pem

  rm "${output}"/client-*.pem
  client_key="${output}"/client-key.pem
  client_req="${output}"/client-req.pem

  openssl req -newkey rsa:4096 -sha256 -nodes \
    -keyout "${client_key}" \
    -out "${client_req}" \
    -subj "/C=CN/ST=HangZhou/L=China/O=YeYing/OU=Application/CN=*.${domain}/emailAddress=community.yeying@gmail.com"

  # Use CA's private key to sign client's CSR and get back the signed certificate
  client_cert="${output}"/client-cert.pem
  client_ext="${output}"/client-ext.cnf
  echo "subjectAltName=DNS:*.${domain},DNS:localhost,IP:0.0.0.0" >"${client_ext}"
  openssl x509 -req -in "${client_req}" -days 60 -CA "${ca_cert}" -CAkey "${ca_key}" -CAcreateserial \
    -out "${client_cert}" \
    -extfile "${client_ext}"

  echo "Client's signed certificate"
  openssl x509 -in "${client_cert}" -noout -text
fi

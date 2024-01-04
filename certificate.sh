#!/bin/sh

base_name="${0##*/}"
runtime_directory=$(
  cd "$(dirname "$0")" || exit 1
  pwd
)

usage() {
  printf "Usage: %s\n \
    -a <Specify the action for cert: generate, check and sign so on> \n \
    -t <Specify the generate cert type, such as ca, csr> \n \
    -o <Specify the output directory, default script directory> \n \
    -e <Specify the email, default yeying.community@gmail.com \n \
    -d <Specify the domain name, such as yeying.pub or odsn.pub and so on> \n \
    -f <Specify the cert file> \n \
    " "${base_name}"
  exit 1
}

if [ $# -eq 0 ]; then
  usage
fi

# For macos`s getopt, reference: https://formulae.brew.sh/formula/gnu-getopt
while getopts ":t:d:o:a:f:e:" o; do
  case "${o}" in
  a)
    action=${OPTARG}
    ;;
  d)
    domain=${OPTARG}
    ;;
  t)
    type=${OPTARG}
    ;;
  o)
    output=${OPTARG}
    ;;
  f)
    crt_file=${OPTARG}
    ;;
  e)
    email=${OPTARG}
    ;;
  *)
    usage
    ;;
  esac
done
shift $((OPTIND - 1))

if [ -z "${output}" ]; then
  output="${runtime_directory}/output"
fi

crt_dir="${output}/crt"
ca_dir="${output}/ca"

echo "use action=${action}"
if [ "${action}" == "check" ]; then
  echo "Check certificate=${crt_file}" 
  openssl x509 -in ${crt_file} -noout -text
elif [ "${action}" == "sign" ]; then
  # Use CA's private key to sign csr and get back the signed certificate
  csr="${crt_dir}"/certificate.csr
  crt="${crt_dir}"/certificate.crt
  ext="${crt_dir}"/certificate.ext

  ca_crt="${ca_dir}"/ca.crt
  ca_key="${ca_dir}"/ca.key

  echo "subjectAltName=DNS:*.${domain},DNS:localhost,IP:0.0.0.0" >"${ext}"
  openssl x509 -req -in "${csr}" -days 180 -CA "${ca_crt}" -CAkey "${ca_key}" -CAcreateserial \
    -out "${crt}" \
    -extfile "${ext}"

  echo "Certificate signed"
  openssl x509 -in "${crt}" -noout -text   
elif [ "${action}" == "generate" ]; then
  if [ -z "${type}" ]; then
    echo "Please specify the generate type, such as ca or csr!"
    usage
  fi

  if [ -z "${domain}" ]; then
    echo "Please specify the domain to generate!"
    usage
  fi

  if [ -z "${email}" ]; then
    email=yeying.community@gmail.com
  fi

  if [ "${type}" == "ca" ]; then
    echo "Generate CA's private key and self-signed certificate"
    mkdir -p "${ca_dir}"

    ca_crt="${ca_dir}"/ca.crt
    ca_key="${ca_dir}"/ca.key
  
    openssl req -x509 -newkey rsa:4096 -sha256 -days 365 -nodes \
      -keyout "${ca_key}" \
      -out "${ca_crt}" \
      -subj "/C=CN/ST=JiangSu/L=NanJing/O=Community/OU=YeYing/CN=*.${domain}/emailAddress=${email}"
  
    echo "CA's self-signed certificate"
    openssl x509 -in "${ca_crt}" -noout -text
  elif [ "${type}" == "csr" ]; then
    echo "Generate private key and certificate signing request (CSR)"
    mkdir -p "${crt_dir}"

    ca_crt="${ca_dir}"/ca.crt
    ca_key="${ca_dir}"/ca.key
  
    key="${crt_dir}"/certificate.key
    csr="${crt_dir}"/certificate.csr

    openssl req -newkey rsa:4096 -sha256 -nodes \
      -keyout "${key}" \
      -out "${csr}" \
      -subj "/C=CN/ST=JiangSu/L=NanJing/O=Community/OU=YeYing/CN=*.${domain}/emailAddress=${email}"
  fi
fi


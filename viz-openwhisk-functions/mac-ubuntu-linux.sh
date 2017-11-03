#!/bin/bash
source credentials.env

function usage() {
  echo -e "Usage: $0 [--install,--uninstall,--clear,--help]"
}

function help() {
  echo "Installs / Uninstalls Unstructured Data Processor in/from Bluemix"
  echo "Usage: $0 [--install,--uninstall,--clear,--help]"
}

function install() {
  echo "Setting the OpenWhisk properties in a namespace"
  bx wsk property set --apihost ${API_HOST} --auth ${OW_AUTH_KEY} --namespace "${BLUEMIX_ORG}_${BLUEMIX_SPACE}"

  echo "Binding cloudant"
  bx wsk package bind /whisk.system/cloudant \
    simulate-iot-cloudant\
    -p dbname $CLOUDANT_db\
    -p username $CLOUDANT_username\
    -p password $CLOUDANT_password\
    -p host $CLOUDANT_host

  echo "Binding IoT Gateway"
  bx wsk package bind /watson-iot/iot-gateway wiotp-gateway -p org $ORGID \
    -p gatewayTypeId $GATEWAYTYPEID \
    -p gatewayToken $GATEWAYTOKEN \
    -p gatewayId $GATEWAYID \
    -p eventType $EVENTTYPE

  echo "Creating actions"
  bx wsk action create cloudant-mapper db-mapper.js #-p targetNamespace $CURRENT_NAMESPACE
  bx wsk action create invoke-visual-recognition visual-recognition.js -p apikey $WATSON_key

  bx wsk action create visual-recognition-iot-sequence --sequence cloudant-mapper,simulate-iot-cloudant/read,invoke-visual-recognition,wiotp-gateway/publishEvent

  echo "Creating trigger"
  #bx wsk trigger create simulate-iot-cloudant/simulate-iot-cloudant-trigger --feed simulate-iot-cloudant/changes
  bx wsk trigger create simulate-iot-cloudant-trigger --feed /whisk.system/cloudant/changes -p dbname $CLOUDANT_db\
    -p username $CLOUDANT_username\
    -p password $CLOUDANT_password\
    -p host $CLOUDANT_host

  echo "Creating rule"
  bx wsk rule create simulate-iot-rule /${BLUEMIX_ORG}_${BLUEMIX_SPACE}/simulate-iot-cloudant-trigger /${BLUEMIX_ORG}_${BLUEMIX_SPACE}/visual-recognition-iot-sequence
  bx wsk action get --summary /whisk.system/alarms/alarm
}

function uninstall() {
  echo "Setting the OpenWhisk properties in a namespace"
  bx wsk property set --apihost ${API_HOST} --auth ${OW_AUTH_KEY} --namespace "${BLUEMIX_ORG}_${BLUEMIX_SPACE}"

  echo "Deleting rule"
  bx wsk rule delete simulate-iot-rule

  echo "Deleting actions"
  bx wsk action delete visual-recognition-iot-sequence

  bx wsk action delete cloudant-mapper
  bx wsk action delete invoke-visual-recognition

  echo "Deleting trigger"
  bx wsk trigger delete simulate-iot-cloudant-trigger

  echo "Delete the binding"
  bx wsk package delete simulate-iot-cloudant
  bx wsk package delete wiotp-gateway
}

function clear() {
  echo "Clearing environmental variables..."

  # Bluemix variables
  echo "Resetting Bluemix variables"
  unset BLUEMIX_ORG
  unset BLUEMIX_SPACE

  # OpenWhisk variables
  echo "Clearing OpenWhisk variables"
  unset API_HOST
  unset OW_AUTH_KEY
  unset CURRENT_NAMESPACE
  unset PACKAGE_NAME

  # Cloudant service variables
  echo "Clearing Cloudant service variables"
  unset CLOUDANT_username
  unset CLOUDANT_password
  unset CLOUDANT_host
  unset CLOUDANT_db

  # Watson Visual Recognition service variables
  echo "Clearing Watson Visual Recognition service variables"
  unset WATSON_key

  # Watson IoT Gateway variables
  echo "Clearing IoT service variables"
  unset ORGID
  unset GATEWAYTYPEID
  unset GATEWAYTOKEN
  unset GATEWAYID
  unset EVENTTYPE
}

case "$1" in
  "--install" )
      install
      clear
      ;;

  "--uninstall" )
      uninstall
      clear
      ;;

  "--help" )
      help
      ;;

  * )
      usage
      ;;
esac

::==============================================================================
:: FILE:         install.sh
:: USAGE:        install.sh [--install,--uninstall,--help]
:: DESCRIPTION:  Installs / Uninstalls simulate-iot for Visual Recognition in Bluemix
:: OPTIONS:      see :CASE--help below
:: AUTHOR:       Hari hara prasad Viswanthan
:: COMPANY:      IBM
:: VERSION:      2.0
::==============================================================================
@ECHO OFF
SET EXIT_CODE=0
IF NOT "%1"== "--install"  IF NOT "%1"== "--uninstall" IF NOT "%1"== "--help" ( SET  EXIT_CODE=1 && GOTO:CASE--help)

GOTO:CASE%1

:CASE--install
SETLOCAL
FOR /f "delims=" %%x IN (credentials.cfg) DO ( ECHO %%x|findstr "=" > NUL &&(set %%x))

ECHO Setting the OpenWhisk properties in a namespace
bx wsk property set --apihost %API_HOST% --auth %OW_AUTH_KEY% --namespace "%BLUEMIX_ORG%_%BLUEMIX_SPACE%"

ECHO Binding cloudant
bx wsk package bind /whisk.system/cloudant simulate-iot-cloudant -p dbname %CLOUDANT_db% -p username %CLOUDANT_username% -p password %CLOUDANT_password% -p host %CLOUDANT_host%

ECHO Binding IoT Gateway
bx wsk package bind /watson-iot/iot-gateway wiotp-gateway -p org %ORGID%  -p gatewayTypeId %GATEWAYTYPEID% -p gatewayId %GATEWAYID% -p gatewayToken %GATEWAYTOKEN% -p eventType %EVENTTYPE%


ECHO Creating actions
bx wsk action create cloudant-mapper db-mapper.js
bx wsk action create invoke-visual-recognition visual-recognition.js -p apikey %WATSON_key%
bx wsk action create visual-recognition-iot-sequence --sequence cloudant-mapper,simulate-iot-cloudant/read,invoke-visual-recognition,wiotp-gateway/publishEvent

ECHO Creating trigger
bx wsk trigger create simulate-iot-cloudant-trigger --feed /whisk.system/cloudant/changes -p dbname %CLOUDANT_db% -p username %CLOUDANT_username% -p password %CLOUDANT_password% -p host %CLOUDANT_host%
bx wsk action get --summary /whisk.system/alarms/alarm

ECHO Creating rule
bx wsk rule create simulate-iot-rule simulate-iot-cloudant-trigger visual-recognition-iot-sequence
ENDLOCAL
GOTO:endall

:CASE--uninstall
SETLOCAL
FOR /f "delims=" %%x IN (credentials.cfg) DO ( ECHO %%x|findstr "=" > NUL &&(set %%x))

ECHO Setting the OpenWhisk properties in a namespace
bx wsk property set --apihost %API_HOST% --auth %OW_AUTH_KEY% --namespace "%BLUEMIX_ORG%_%BLUEMIX_SPACE%"

ECHO Deleting rule
bx wsk rule delete simulate-iot-rule

ECHO Deleting actions
bx wsk action delete visual-recognition-iot-sequence

bx wsk action delete cloudant-mapper
bx wsk action delete invoke-visual-recognition

ECHO Deleting trigger
bx wsk trigger delete simulate-iot-cloudant-trigger

ECHO Delete the binding
bx wsk package delete simulate-iot-cloudant
bx wsk package delete wiotp-gateway

ENDLOCAL
GOTO:endall

:CASE--help
ECHO Installs / Uninstalls Unstructured Data Processor in/from Bluemix
ECHO Usage: %0 [--install,--uninstall,--clear,--help]
GOTO:endall

:endall
EXIT /B %EXIT_CODE%

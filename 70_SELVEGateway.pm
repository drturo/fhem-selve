package main;
use strict;
use warnings;
use DevIo;
use XML::Simple;
use Data::Dumper;
use MIME::Base64 qw( encode_base64 );

my %SELVEGateway_gets = (
	"ping"		     => "selve.GW.service.ping",
	"getState"		 => "selve.GW.service.getState",
    "getVersion"	 => "selve.GW.service.getVersion",
    "reset"          => "selve.GW.service.reset",
	"factoryreset"   => "selve.GW.service.factoryReset",
	"getLED"		 => "selve.GW.service.getLED",

    "iveoGetConfig"	 => "selve.GW.iveo.getConfig",
	"iveoGetIds"	 => "selve.GW.iveo.getIDs",
	"iveoGetRepeater"=> "selve.GW.iveo.getRepeater",

    "getEvent" 		 => "selve.GW.param.getEvent",
	"getDuty"	     => "selve.GW.param.getDuty",
	"getRF"		     => "selve.GW.param.getRF",
    "getForward" 	 => "selve.GW.param.getForward",
    
    "DEVscanStart"   => "selve.GW.device.scanStart",
    "DEVscanStop"    => "selve.GW.device.scanStop",
    "DEVscanResult"  => "selve.GW.device.scanResult",
    "DEVgetIDs"      => "selve.GW.device.getIDs",
    "DEVgetInfo"     => "selve.GW.device.getInfo",
    "DEVgetValues"   => "selve.GW.device.getValues",
  
    "SensorTeachStart"  => "selve.GW.sensor.teachStart",
    "SensorTeachStop"   => "selve.GW.sensor.teachStop",
    "SensorTeachResult" => "selve.GW.sensor.teachResult",
    "SensorGetIDs"      => "selve.GW.sensor.getIDs",
    "SensorGetInfo"     => "selve.GW.sensor.getInfo",
    "SensorGetValues"   => "selve.GW.sensor.getValues",

    "SenderTeachStart"  => "selve.GW.sender.teachStart",
    "SenderTeachStop"   => "selve.GW.sender.teachStop",
    "SenderTeachResult" => "selve.GW.sender.teachResult",
    "SenderGetIDs"      => "selve.GW.sender.getIDs",
    "SenderGetInfo"     => "selve.GW.sender.getInfo",
    "SenderGetValues"   => "selve.GW.sender.getValues",
  
    "GroupRead"      => "selve.GW.group.read",
    "GroupGetIDs"    => "selve.GW.group.getIDs"
);

my %SELVEGateway_sets = (
    "setLED"		  => "selve.GW.service.setLED",
    "reconnect"		  => "reconnect",
    
	"setForward" 	  => "selve.GW.param.setForward",
	"setEvent"		  => "selve.GW.param.setEvent",
    
    "DeviceSave"            => "selve.GW.device.save",
    "DeviceSetFunction"     => "selve.GW.device.setFunction",
    "DeviceSetLabel"        => "selve.GW.device.setLabel",
    "DeviceSetType"         => "selve.GW.device.setType",
    "DeviceDelete"          => "selve.GW.device.delete",
    "DeviceWriteManual"     => "selve.GW.device.writeManual",

    "SensorSetLabel"        => "selve.GW.sensor.setLabel",
    "SensorDelete"          => "selve.GW.sensor.delete",
    "SensorWriteManual"     => "selve.GW.sensor.writeManual",

    "SenderSetLabel"        => "selve.GW.sender.setLabel",
    "SenderDelete"          => "selve.GW.sender.delete",
    "SenderWriteManual"     => "selve.GW.sender.writeManual",
    
    "commandDevice"   => "selve.GW.command.device",
    "commandGroup"    => "selve.GW.command.group",
    "commandGroupMan" => "selve.GW.command.groupMan",
   
    "GroupWrite"      => "selve.GW.group.write", 
    "GroupDelete"     => "selve.GW.group.delete",

    "iveoSetConfig" 		=> "selve.GW.iveo.setConfig",
	"iveoCommandTeach" 		=> "selve.GW.iveo.commandTeach",
	"iveoSetRepeater"		=> "selve.GW.iveo.setRepeater",
	"iveoCommandManual" 	=> "selve.GW.iveo.commandManual",
	"iveoCommandManualGroup"=> "selve.GW.iveo.commandManualGroup",
	"iveoCommandAutomatic"	=> "selve.GW.iveo.commandAutomatic"
);

my %SELVEGateway_commands = (
	"selve.GW.service.ping"				    => "<methodCall><methodName>selve.GW.service.ping</methodName></methodCall>",
	"selve.GW.service.getState" 			=> "<methodCall><methodName>selve.GW.service.getState</methodName></methodCall>",
	"selve.GW.service.getVersion"			=> "<methodCall><methodName>selve.GW.service.getVersion</methodName></methodCall>",
	"selve.GW.service.reset"				=> "<methodCall><methodName>selve.GW.service.reset</methodName></methodCall>",
	"selve.GW.service.factoryReset"			=> "<methodCall><methodName>selve.GW.service.factoryReset</methodName></methodCall>",
	"selve.GW.service.setLED"			    => "<methodCall><methodName>selve.GW.service.setLED</methodName><array><int>§§</int></array></methodCall>",
	"selve.GW.service.getLED"				=> "<methodCall><methodName>selve.GW.service.getLED</methodName></methodCall>",
    
	"selve.GW.param.setForward"				=> "<methodCall><methodName>selve.GW.param.setForward</methodName><array><int>§§</int></array></methodCall>",
	"selve.GW.param.getForward"			    => "<methodCall><methodName>selve.GW.param.getForward</methodName></methodCall>",
	"selve.GW.param.setEvent"				=> "<methodCall><methodName>selve.GW.param.setEvent</methodName><array><int>§§</int><int>§§</int><int>§§</int><int>§§</int><int>§§</int></array></methodCall>",
	"selve.GW.param.getEvent"		    	=> "<methodCall><methodName>selve.GW.param.getEvent</methodName></methodCall>",
	"selve.GW.param.getDuty"	        	=> "<methodCall><methodName>selve.GW.param.getDuty</methodName></methodCall>",
	"selve.GW.param.getRF"		            => "<methodCall><methodName>selve.GW.param.getRF</methodName></methodCall>",
    
    "selve.GW.device.scanStart"             => "<methodCall><methodName>selve.GW.device.scanStart</methodName></methodCall>",
    "selve.GW.device.scanStop"              => "<methodCall><methodName>selve.GW.device.scanStop</methodName></methodCall>",
    "selve.GW.device.scanResult"            => "<methodCall><methodName>selve.GW.device.scanResult</methodName></methodCall>",
    "selve.GW.device.save"                  => "<methodCall><methodName>selve.GW.device.save</methodName><array><int>§§</int></array></methodCall>",
    "selve.GW.device.getIDs"                => "<methodCall><methodName>selve.GW.device.getIDs</methodName></methodCall>",
    "selve.GW.device.getInfo"               => "<methodCall><methodName>selve.GW.device.getInfo</methodName><array><int>§§</int></array></methodCall>",
    "selve.GW.device.getValues"             => "<methodCall><methodName>selve.GW.device.getValues</methodName><array><int>§§</int></array></methodCall>",
    
    "selve.GW.group.read"                   => "<methodCall><methodName>selve.GW.group.read</methodName><array><int>§§</int></array></methodCall>",
    "selve.GW.group.getIDs"                 => "<methodCall><methodName>selve.GW.group.getIDs</methodName></methodCall>",
    "selve.GW.group.write"                  => "<methodCall><methodName>selve.GW.group.write</methodName><array><int>§§</int><base64>§§</base64><string>§§</string></array></methodCall>",
    "selve.GW.group.delete"                 => "<methodCall><methodName>selve.GW.group.delete</methodName><array><int>§§</int></array></methodCall>",
    
    "selve.GW.device.setFunction"           => "<methodCall><methodName>selve.GW.device.setFunction</methodName><array><int>§§</int><int>§§</int></array></methodCall>",
    "selve.GW.device.setLabel"              => "<methodCall><methodName>selve.GW.device.setLabel</methodName><array><int>§§</int><string>§§</string></array></methodCall>",
    "selve.GW.device.setType"               => "<methodCall><methodName>selve.GW.device.setType</methodName><array><int>§§</int><int>§§</int></array></methodCall>",
    "selve.GW.device.delete"                => "<methodCall><methodName>selve.GW.device.delete</methodName><array><int>§§</int></array></methodCall>",
    "selve.GW.device.writeManual"           => "<methodCall><methodName>selve.GW.device.writeManual</methodName><array><int>§§</int><int>§§</int><string>§§</string><int>§§</int></array></methodCall>",
    
    "selve.GW.command.device"               => "<methodCall><methodName>selve.GW.command.device</methodName><array><int>§§</int><int>§§</int><int>§§</int><int>§§</int></array></methodCall>",
    "selve.GW.command.group"                => "<methodCall><methodName>selve.GW.command.group</methodName><array><int>§§</int><int>§§</int><int>§§</int><int>§§</int></array></methodCall>",
    "selve.GW.command.groupMan"             => "<methodCall><methodName>selve.GW.command.groupMan</methodName><array><int>§§</int><int>§§</int><base64>§§</base64><int>§§</int></array></methodCall>",

    "selve.GW.sensor.teachStart"            => "<methodCall><methodName>selve.GW.sensor.teachStart</methodName></methodCall>",
    "selve.GW.sensor.teachStop"             => "<methodCall><methodName>selve.GW.sensor.teachStop</methodName></methodCall>",
    "selve.GW.sensor.teachResult"           => "<methodCall><methodName>selve.GW.sensor.teachResult</methodName></methodCall>",
    "selve.GW.sensor.getIDs"                => "<methodCall><methodName>selve.GW.sensor.getIDs</methodName></methodCall>",
    "selve.GW.sensor.getInfo"               => "<methodCall><methodName>selve.GW.sensor.getInfo</methodName><array><int>§§</int></array></methodCall>",
    "selve.GW.sensor.getValues"             => "<methodCall><methodName>selve.GW.sensor.getValues</methodName><array><int>§§</int></array></methodCall>",
   
    "selve.GW.sensor.setLabel"              => "<methodCall><methodName>selve.GW.sensor.setLabel</methodName><array><int>§§</int><string>§§</string></array></methodCall>",
    "selve.GW.sensor.delete"                => "<methodCall><methodName>selve.GW.sensor.delete</methodName><array><int>§§</int></array></methodCall>",
    "selve.GW.sensor.writeManual"           => "<methodCall><methodName>selve.GW.sensor.writeManual</methodName><array><int>§§</int><int>§§</int><string>§§</string><int>§§</int></array></methodCall>",
 
    "selve.GW.sender.teachStart"            => "<methodCall><methodName>selve.GW.sender.teachStart</methodName></methodCall>",
    "selve.GW.sender.teachStop"             => "<methodCall><methodName>selve.GW.sender.teachStop</methodName></methodCall>",
    "selve.GW.sender.teachResult"           => "<methodCall><methodName>selve.GW.sender.teachResult</methodName></methodCall>",
    "selve.GW.sender.getIDs"                => "<methodCall><methodName>selve.GW.sender.getIDs</methodName></methodCall>",
    "selve.GW.sender.getInfo"               => "<methodCall><methodName>selve.GW.sender.getInfo</methodName><array><int>§§</int></array></methodCall>",
    "selve.GW.sender.getValues"             => "<methodCall><methodName>selve.GW.sender.getValues</methodName><array><int>§§</int></array></methodCall>",
   
    "selve.GW.sender.setLabel"              => "<methodCall><methodName>selve.GW.sender.setLabel</methodName><array><int>§§</int><string>§§</string></array></methodCall>",
    "selve.GW.sender.delete"                => "<methodCall><methodName>selve.GW.sender.delete</methodName><array><int>§§</int></array></methodCall>",
    "selve.GW.sender.writeManual"           => "<methodCall><methodName>selve.GW.sender.writeManual</methodName><array><int>§§</int><int>§§</int><string>§§</string><int>§§</int></array></methodCall>",
 
    "selve.GW.iveo.getConfig"				=> "<methodCall><methodName>selve.GW.iveo.getConfig</methodName><array><int>§§</int></array></methodCall>",
	"selve.GW.iveo.getIDs" 					=> "<methodCall><methodName>selve.GW.iveo.getIDs</methodName></methodCall>",
	"selve.GW.iveo.getRepeater"				=> "<methodCall><methodName>selve.GW.iveo.getRepeater</methodName></methodCall>",
	"selve.GW.iveo.setConfig"				=> "<methodCall><methodName>selve.GW.iveo.setConfig</methodName><array><int>§§</int><int>§§</int><int>§§</int></array></methodCall>",
	"selve.GW.iveo.commandTeach"			=> "<methodCall><methodName>selve.GW.iveo.commandTeach</methodName><array><int>§§</int></array></methodCall>",
	"selve.GW.iveo.setRepeater"				=> "<methodCall><methodName>selve.GW.iveo.setRepeater</methodName><array><int>§§</int></array></methodCall>",
	"selve.GW.iveo.commandManual"			=> "<methodCall><methodName>selve.GW.iveo.commandManual</methodName><array><base64>§§</base64><int>§§</int></array></methodCall>",
	"selve.GW.iveo.commandManualGroup"		=> "<methodCall><methodName>selve.GW.iveo.commandManual</methodName><array><base64>§§</base64><int>§§</int></array></methodCall>",
	"selve.GW.iveo.commandAutomatic"		=> "<methodCall><methodName>selve.GW.iveo.commandAutomatic</methodName><array><base64>§§</base64><int>§§</int></array></methodCall>"
);

sub SELVEGateway_Initialize($) {
    my ($hash) = @_;
    my $name = $hash->{NAME};

    $hash->{DefFn}      = 'SELVEGateway_Define';
    $hash->{UndefFn}    = 'SELVEGateway_Undef';
    $hash->{SetFn}      = 'SELVEGateway_Set';
    $hash->{GetFn}      = 'SELVEGateway_Get';
    $hash->{AttrFn}     = 'SELVEGateway_Attr';
    $hash->{ReadFn}     = 'SELVEGateway_Read';
	$hash->{WriteFn} 	= 'SELVEGateway_Write';
	$hash->{ReadyFn} 	= 'SELVEGateway_Ready';
	$hash->{NotifyFn} 	= 'SELVEGateway_Notify';
	$hash->{NOTIFYDEV}  = "$name";
	$hash->{nextOpenDelay} = 60;
	
	$hash->{Clients} =
		"SELVECommeo:SELVEsensor:SELVEsender:SELVE";
	my %mc = (
		"1:SELVECommeo"   => "^SELVECommeo@@.*",
		"2:SELVEsensor"   => "^SELVEsensor@@.*",
		"3:SELVEsender"   => "^SELVEsender@@.*",
	);
	$hash->{MatchList} = \%mc;

    $hash->{AttrList} =
          "verbose room "
        . $readingFnAttributes;
    $hash->{commandqueue} = ();
    $hash->{commands_pending} = 0;
    $hash->{command_running} = ();
}

sub SELVEGateway_Define($$) {
    my ($hash, $def) = @_;
    my @param = split('[ \t][ \t]*', $def);
	
	if(@param != 3) {
		my $msg = "wrong syntax: define <name> SELVEGateway {devicename[\@baudrate] | devicename\@directio}";
		Log3 undef, 2, $msg;
    return $msg;

	}
	
	my $name = $param[0];

	my $dev = $param[2];
	$dev .= "\@115200" if( $dev !~ m/\@/ );

    $hash->{DeviceName}  = $dev;
    $hash->{name} = $param[0];
	DevIo_CloseDev($hash) if(DevIo_IsOpen($hash));  
	my $ret = DevIo_OpenDev($hash, 0 , "SELVEGateway_DoInit");
    return $ret;
}

sub SELVEGateway_Undef($$) {
    my ( $hash, $name) = @_;       
	DevIo_CloseDev($hash);         
	RemoveInternalTimer($hash);    
	return undef;
}

sub SELVEGateway_DoInit($) {
	my ($hash) = @_;
	my $name = $hash->{NAME};
	
	return undef;
}

sub SELVEGateway_Read($) {
	my ($hash) = @_;
	my $name = $hash->{NAME};
	
	# einlesen der bereitstehenden Daten
	my $buf = DevIo_SimpleRead($hash);		
	return "" if ( !defined($buf) );
	Log3 $name, 5, "SELVEGateway: Received data: ".$buf; 
	
	$buf =~ s/\n//g;
	$hash->{buffer} .= $buf;
	$hash->{buffer} =~ s/>\s+</></g; 
	
	while($hash->{buffer} =~ /<method(Response|Call)>.*?<\/method\g1>/p) {
		Log3 $hash, 5, "SELVEGateway: FOUND Method Response or Call";
		my $method = "method" . $1;
		my $xmlContent = ${^MATCH};
		$hash->{lastGwResponse} = ${^MATCH};
		$hash->{buffer} = ${^POSTMATCH};
		my $header = ${^PREMATCH};
		$header =~ s/(\s|\r)*<\?.*?UTF-8\"\?>\s*//g;
		if ($header ne "") {
			$hash->{INVALID}++;
			Log3 $hash, 3, "SELVEGateway: ERROR: discarding unreadable input: \"$header\"";
		}
		# Objekt erstellen<br />
		#my $xml = new XML::Simple;
        my $xml = XML::Simple->new(ForceArray => ["$method"], KeyAttr => []);
		# XML-Datei einlesen<br />
		my $data = eval{$xml->XMLin($xmlContent)};
		$data{SELVEresponse} = $data;
		my $AktorID = "";
		my $SourceType;
		
		if(!$@) {
			Log3 $hash, 5, "SELVEGateway: " . Dumper($data);
			if ($method eq "methodResponse") {
				$hash->{command_last_running} = $hash->{command_running} unless $hash->{command_last_running} > 0;
			    $hash->{command_running} = ();
                SELVEGateway_RunCommand($hash) if $hash->{commands_pending} > 0;
            }
			my $cmd = "";
			if(!defined($data->{fault}))
            {
				$hash->{MSGIN}++;
				$hash->{lastResponseData} = $data->{array};
				if ($method eq "methodCall") {
					$cmd = $data->{methodName};
				} elsif(ref $data->{array}->{string} eq "ARRAY") {
					$cmd = $data->{array}->{string}[0];
				} else {
					$cmd = $data->{array}->{string};
				}
				Log3 $hash, 4, "SELVEGateway: received message: " . $cmd;
				if($cmd eq 'selve.GW.service.getState')
                {
					my $newGwState = 0;
					my $stateCode = $data->{array}->{int};
					
					if($stateCode == 0) {$newGwState = "Bootloader";}
					elsif($stateCode == 1) {$newGwState = "Update";}
					elsif($stateCode == 2) {$newGwState = "StartUp";}
					elsif($stateCode == 3) {$newGwState = "Ready";};
					$hash->{gwState} = $newGwState;
				} elsif ($cmd eq 'selve.GW.param.getDuty' or $cmd eq "selve.GW.event.dutyCycle")
                {
                    my @State = ("Senden wird nicht blockiert.", "Senden wird bei 100 % Auslastung blockiert.");
					$hash->{gwDuty} = $State[$data->{array}->{int}[0]]. " --> " .$data->{array}->{int}[1]. "% Auslastung" ;
					readingsBeginUpdate($hash);
        			readingsBulkUpdate($hash, "rf-status", $data->{array}->{int}[0] ? "blocked" : "sending");
        			readingsBulkUpdate($hash, "rf-usage", $data->{array}->{int}[1]);
        			readingsEndUpdate($hash, 1);
				} elsif ($cmd eq 'selve.GW.service.getVersion')
                {
					my @responseData = $data->{array}->{int};
					for(my $i = 0; $i < @responseData; $i++)
                    {
						$responseData[0][$i] = hex($responseData[0][$i]);
					}
					my $firmwareVersion = $responseData[0][0] . "." . $responseData[0][1] . "." . $responseData[0][2] . "." . $responseData[0][5];
					my $gwXMLVersion = $responseData[0][3] . "." . $responseData[0][4];
					$hash->{gwFirmwareVersion} = $firmwareVersion;
					$hash->{gwXMLVersion} = $gwXMLVersion;
					$hash->{gwSerialNo} = $data->{array}->{string}[1];
				} elsif ($cmd eq 'selve.GW.service.getLED')
                {
                    my $newGwState = 0;
					my $stateCode = $data->{array}->{int};
					
					if($stateCode == 0) {$newGwState = "LED Anzeige ist abgeschaltet.";}
					elsif($stateCode == 1) {$newGwState = "LED Anzeige ist eingeschaltet.";}
					
					$hash->{gwLEDModus} = $newGwState;
				} elsif ($cmd eq 'selve.GW.param.getForward')
                {
                    my $newGwState = 0;
					my $stateCode = $data->{array}->{int};
					
					if($stateCode == 0) {$newGwState = "Das Forwarding ist abgeschaltet.";}
					elsif($stateCode == 1) {$newGwState = "Das Forwarding ist eingeschaltet.";}
					
					$hash->{gwForwardModus} = $newGwState;
				} elsif ($cmd eq 'selve.GW.param.getEvent')
                {
                    my @StateEventDev = ("Ereignisse werden nicht gesendet.", "Ereignisse werden gesendet.");
                    my @StateEventLog = ("Logs werden nicht gesendet.", "Logs werden gesendet.");
                    my @StateEventDuty = ("Sich ändernde Funkressourcennutzung werden nicht gesendet.", "Sich ändernde Funkressourcennutzung werden gesendet.");
                    
                    my $response = "gwEventDevice: " . $StateEventDev[$data->{array}->{int}[0]] . " | ";
                    $response .= "gwEventSensor: " . $StateEventDev[$data->{array}->{int}[1]] . " | ";
                    $response .= "gwEventSender: " . $StateEventDev[$data->{array}->{int}[2]] . " | ";
                    $response .= "gwLogging: " . $StateEventLog[$data->{array}->{int}[3]] . " | ";
                    $response .= "gwEventDuty: " . $StateEventDuty[$data->{array}->{int}[4]];                
       
                    $hash->{gwEvent} = $response;
				} elsif ($cmd eq 'selve.GW.param.getRF')
                {
					$hash->{gwRF} = "Network: " . $data->{array}->{int}[0] . " | ResetCount: " . $data->{array}->{int}[1] . " | RFBaseID: " . $data->{array}->{int}[2] . " | SensorNetwork: " . $data->{array}->{int}[3] . " | FSensorID: " . $data->{array}->{int}[4];
                } elsif ($cmd =~ /selve.GW.(device|sensor|sender).(scan|teach)Result/)
                {
                    my $type = $1; my $scan=$2;
                    my @StateName = ("Idle", "Run", "Verify", "End Success", "End Failed");
                    my $ResponseState = $StateName[$data->{array}->{int}[0]];
                    
					my $ResponseMask = unpack("B64", decode_base64($data->{array}->{base64}));
                    $ResponseMask =~ s/(.{8})/$1 /g;
                    
					#$ResponseMask .= "pack:" . pack("L2", 2048) . " base64: ".encode_base64( pack("L2", 2048));
                    #$ResponseMask .= " DEC=". 2 ** 11 . " Wurzel: ". 2048 ** (1/11). "log: " .log(2048)/log(2). "ungepackt:".log(unpack("L2", decode_base64("AAgAAAAAAAA=")))/log(2);
                    
					$hash->{$1 . $2 . "Response"} = "Status: " . $ResponseState . " | Anz. Gefunden: " . $data->{array}->{int}[1] . " | Mask: " . $ResponseMask;
                } elsif ($cmd =~ /selve.GW.(device|sensor|sender).getIDs/)
                {
					my $type = $1;
					my $ResponseMask = unpack("B64", decode_base64($data->{array}->{base64}));
                    $ResponseMask =~ s/(.{8})/$1 /g;
                    
					$hash->{$1 . "getIDs"} = "Mask: " . $ResponseMask;
                } elsif ($cmd =~ /selve.GW.(device|sensor|sender).get(Info|Values)/ or  
                	    $cmd =~ /selve.GW.event.(device|sensor|sender)/)
                {
                    $SourceType = $1;
                    $AktorID =  $data->{array}->{int}[0];

				} elsif ($cmd eq 'selve.GW.group.getIDs')
                {
					my $ResMask = unpack("B32", decode_base64($data->{array}->{base64}));
                    $ResMask =~ s/(.{8})/$1 /g;
                    
					$hash->{gwgroupIDs} = "Mask: " .$data->{array}->{base64} . $ResMask;
				} elsif ($cmd eq 'selve.GW.command.device')
                {
					my $stateCode = $data->{array}->{int};
					Log3 $hash, 4, "SELVEGateway: selve.GW.command.device returned $stateCode";
				} elsif ($cmd eq 'selve.GW.command.result')
                {
					$hash->{"command"} = $data->{array}->{int}[0];
					$hash->{"command_type"} = $data->{array}->{int}[1];
					$hash->{"command_result"} = $data->{array}->{int}[2];
					my $ResMask = unpack("B32", decode_base64($data->{array}->{base64}[0]));
                    $ResMask =~ s/(.{8})/$1 /g;
                    $hash->{"command_success"} = $ResMask;
                    $ResMask = unpack("B32", decode_base64($data->{array}->{base64}[1]));
                    $ResMask =~ s/(.{8})/$1 /g;
                    $hash->{"command_failed"} = $ResMask;
                    my ($CommandString,  @param) = @{$hash->{command_last_running}} if ref $hash->{command_last_running} eq "ARRAY";
                    $hash->{command_last_running} = ();
                    Log3 $hash, 4, "SELVEGateway: Command completed: @param, result: $hash->{command_result}";
				} elsif ($cmd eq 'selve.GW.event.log')
                {
					$hash->{"LogType"} = (ref $data->{array}->{int} eq "ARRAY") ? $data->{array}->{int}[0] : $data->{array}->{int};
					$hash->{"LogCode"} = $data->{array}->{string}[1];
					$hash->{"LogStamp"} = $data->{array}->{string}[2];
					$hash->{"LogValue"} = $data->{array}->{string}[3];
					$hash->{"LogDescription"} = $data->{array}->{string}[4];
				} else
				{
					Log3 $hash, 3, "SELVEGateway: unknown or unimplemented function: $cmd";
				}
			} else {
				$hash->{FAULT}++;
				$hash->{FAULTmessage} = $data->{fault}->{array}->{string};
				$hash->{FAULTid} = $data->{fault}->{array}->{int};
				Log3 $hash, 3, "SELVEGateway: FAULT FOUND: message: ". $data->{fault}->{array}->{string} . ", ID: " . $data->{fault}->{array}->{int};
			}
			if ($AktorID ne "") {
				$SourceType = "Commeo" if $SourceType eq "device";
				Dispatch($hash, "SELVE" . $SourceType . "@@" . $cmd . ":" . $AktorID, undef);

			}
			delete $data{SELVEresponse};    
		} 
	}
	
	return undef;
}

sub SELVEGateway_Write($$@) {
	my ($hash, $cmd, @param) = @_;
	Log3 $hash, 5, "SELVEGateway: GW_WRITE called: $cmd";
	return SELVEGateway_SendGatewayCommand($hash, $cmd, @param);
}

sub SELVEGateway_Get($@) {
	my ($hash, $name, @param) = @_;
	
	my $cnt = @param;
	my $rValue = "";
	
	return '"get SELVEGateway" needs at least one argument' if ($cnt < 1);
	
	my $cmd = $param[0];
	
	
	if(!$SELVEGateway_gets{$cmd}) {
		my @cList = keys %SELVEGateway_gets;
		return "Unknown argument $cmd, choose one of " . join(" ", @cList);
	}
	
	my $commandString = $SELVEGateway_gets{$cmd};
	
	$rValue = SELVEGateway_SendGatewayCommand($hash, $commandString, @param);
	
	Log3 $hash, 5, "SELVEGateway: RETURN VALUE GET: " . $rValue;
	
	return undef;
}

sub SELVEGateway_Set($@) {
	my ($hash, $name, @param) = @_;
	
	return '"set SELVEGateway" needs at least one argument' if (int(@param) < 1);
	
	my $cmd = $param[0];
	my $rValue = "";
	
	if(!$SELVEGateway_sets{$cmd})
    {
		my @cList = keys %SELVEGateway_sets;
		for(my $i = 0; $i < @cList; $i++) {
			if($cList[$i] eq "setLED") {
				$cList[$i] = "setLED:0,1";
			} elsif ($cList[$i] eq "setRepeater"){
				$cList[$i] = "setRepeater:0,1";
			}
		}
		return "Unknown argument $cmd, choose one of " . join(" ", @cList);
	}
	
	my $commandString = $SELVEGateway_sets{$cmd};

	Log3 $hash, 5, "SELVEGateway: Set CALLED: cmd:" . $cmd . "; commandString: " . $commandString;

 	if($commandString =~ "selve.*") {
		$rValue = SELVEGateway_SendGatewayCommand($hash, $commandString, @param);
	} else {
 		if($commandString =~ "reconnect") {
 			SELVEGateway_Reconnect($hash);
 			$hash->{commandqueue} = ();
    		$hash->{commands_pending} = 0;
    		$hash->{command_running} = ();
 		}
 		$rValue = $cmd;
 	}

	Log3 $hash, 5, "SELVEGateway: RETURN VALUE SET: " . $rValue;
	
	return undef;
}

sub SELVEGateway_SendGatewayCommand($$@) {
	my ($hash, $commandString, @param) = @_;
	
	my $rValue = undef;
	
	if(defined($SELVEGateway_commands{$commandString})) {
		Log3 $hash, 5, "SELVEGateway: SendGWCommand CALLED: " . $commandString;
		if($commandString eq 'selve.GW.command.groupMan') {
			my @groupList = split(/:/, $param[3]);
			my $groupDec = 0;
			foreach(@groupList) {
				$groupDec += 2 ** $_
			}
			my $groupBase64 = encode_base64(pack("L2",$groupDec));
			$groupBase64 =~ s/\r//;
			$groupBase64 =~ s/\n//;
			$param[3] = $groupBase64;
			Log3 $hash, 5, "SELVEGateway: GROUP - DEC: $groupDec; BASE64: $groupBase64"; 
		}
        elsif($commandString eq 'selve.GW.group.write') {
			my @groupList = split(/:/, $param[2]);
			my $groupDec = 0;
			foreach(@groupList) {
				$groupDec += 2 ** $_
			}
			my $groupBase64 = encode_base64(pack("L2",$groupDec));
			$groupBase64 =~ s/\r//;
			$groupBase64 =~ s/\n//;
			$param[2] = $groupBase64;
			Log3 $hash, 5, "SELVEGateway: GROUP - DEC: $groupDec; BASE64: $groupBase64"; 
		}
		elsif($commandString eq 'selve.GW.iveo.commandManualGroup') {
			my @groupList = split(/:/, $param[1]);
			my $groupDec = 0;
			foreach(@groupList) {
				$groupDec += 2 ** $_
			}
			my $groupBase64 = encode_base64(pack("L2",$groupDec));
			$groupBase64 =~ s/\r//;
			$groupBase64 =~ s/\n//;
			$param[1] = $groupBase64;
			Log3 $hash, 5, "SELVEGateway: GROUP - DEC: $groupDec; BASE64: $groupBase64"; 
		}
		$rValue = SELVEGateway_QueueCommand($hash, $commandString, @param);
	} else {
		Log3 $hash, 2, "SELVEGateway: Unknown command: $commandString";
	}
	
	return $rValue;
}

sub SELVEGateway_QueueCommand($$@) {
	my ($hash, $CommandString, @param) = @_;
	Log3 $hash, 4, "SELVEGateway: Queuing command: $CommandString, @param";
	push @{$hash->{commandqueue}}, [$CommandString, @param];
	$hash->{commands_pending}++;
	SELVEGateway_RunCommand($hash) if $hash->{command_running} == 0;
}

sub SELVEGateway_RunCommand($) {
	my ($hash) = @_;

	my $rValue = undef;
	my ($CommandString,  @param) = @{shift @{$hash->{commandqueue}}};
	$hash->{command_running} = [$CommandString,  @param];
	$hash->{commands_pending}--;
	Log3 $hash, 4, "SELVEGateway: Running command: $CommandString, @param";
	my $xmlCommandString = $SELVEGateway_commands{$CommandString};
	if($xmlCommandString =~ '§§') {
		for(my $i=1; $i < @param; $i++) {
			$xmlCommandString =~ s/§§/$param[$i]/;
		}
	}
	
	Log3 $hash, 5, "SELVEGateway: SendCommand CALLED: " . $xmlCommandString;
	
	if($xmlCommandString ne "") {
		DevIo_SimpleWrite($hash, $xmlCommandString,0);
		$rValue = "Command sent: $xmlCommandString";
	}
	
	return $rValue;
}


sub SELVEGateway_Attr(@) {
	my ($cmd,$name,$attr_name,$attr_value) = @_;
	
	return undef;
}

sub SELVEGateway_Notify($$)
{
  my ($own_hash, $dev_hash) = @_;
  my $ownName = $own_hash->{NAME}; # own name / hash

  return "" if(IsDisabled($ownName)); # Return without any further action if the module is disabled

  my $devName = $dev_hash->{NAME}; # Device that created the events

  return undef if $dev_hash->{NAME} ne $own_hash->{NAME};

  my $events = deviceEvents($dev_hash,1);
  return if( !$events );

  foreach my $event (@{$events}) {
    $event = "" if(!defined($event));
    Log3 $own_hash, 2, "SELVEGateway_Notify: received event: $event";
    if ($event eq "CONNECTED"){
    	;
    }
    # Examples:
    # $event = "readingname: value" 
    # or
    # $event = "INITIALIZED" (for $devName equal "global")
    #
    # processing $event with further code
  }
}

sub SELVEGateway_Ready($)
{
	my ($hash) = @_;
      
	# Versuch eines Verbindungsaufbaus, sofern die Verbindung beendet ist.
	return DevIo_OpenDev($hash, 1, "SELVEGateway_DoInit" )
	 	if($hash->{STATE} eq "disconnected");

	# This is relevant for Windows/USB only
	if(defined($hash->{USBDev})) {
		my $po = $hash->{USBDev};
		my ( $BlockingFlags, $InBytes, $OutBytes, $ErrorFlags ) = $po->status;
		return ( $InBytes > 0 );
	}
}

sub SELVEGateway_Reconnect($) {
	my ($hash) = @_;
	Log3 $hash, 5, "SELVEGateway: Reconnect CALLED";
	DevIo_CloseDev($hash);
	my $ret = DevIo_OpenDev($hash, 0 , "SELVEGateway_DoInit");
	return $ret;
}

1;

=pod
=begin html

<a name="SELVEGateway"></a>
<h3>SELVEGateway</h3>
<ul>
    <i>SELVEGateway</i> implements functions of the SELVE USB Gateway for e.g. shutters.
    <br><br>
    <a name="SELVEGatewaydefine"></a>
    <b>Define</b>
    <ul>
        <i>define <name> SELVEGateway <device></i>
        <br><br>
        Example: <i>define SELVEgw SELVEGateway /dev/ttyUSB0:115200</i>
        <br><br>
        <device> specifies the serial port to communicate with the SELVE USB Gatewy. The name of the serial-device depends on your distribution.
		In this case the device is most probably /dev/ttyUSB0.

		You can also specify a baudrate if the device name contains the @ character, e.g.: /dev/ttyUSB0@115200

		If baudrate not specified standard baudrate 115200 is used. 
    </ul>
    <br>
    
    <a name="SELVEGatewayset"></a>
    <b>Set</b><br>
    <ul>
        <code>set <name> <option> <value></code>
        <br><br>
        You can <i>set</i> any value to any of the following options. They're just there to 
        <i>get</i> them. See <a href="http://fhem.de/commandref.html#set">commandref#set</a> 
        for more info about the set command.
		For more information use SELVE XML Gateway description
        <br><br>
        Options:
        <ul>
			<li><i>setConfig <iveoid> <activity> <type></i><br>
				For more information use SELVE XML Gateway description</li>
			<li><i>commandTeach <iveoid></i><br>
				For more information use SELVE XML Gateway description</li>
			<li><i>setRepeater <on/off></i><br>
				0 = off, 1 = on
				For more information use SELVE XML Gateway description</li>	
			<li><i>commandManual <iveoid> <commandtype></i><br>
				For more information use SELVE XML Gateway description</li>
			<li><i>commandManualGroup <iveoids> <commandtype></i><br>
				For more information use SELVE XML Gateway description</li>
			<li><i>commandAutomatic <iveoid> <commandtype></i><br>
				For more information use SELVE XML Gateway description</li>
			<li><i>setLED <on/off></i><br>
				0 = off, 1 = on
				For more information use SELVE XML Gateway description</li>
        </ul>
    </ul>
    <br>

    <a name="SELVEGatewayget"></a>
    <b>Get</b><br>
    <ul>
        <i>getIveoConfig <iveoid> <option></i>
        <br><br>
        You can <i>get</i> the value of any of the options described in 
        <a href="#SELVEGatewayset">paragraph "Set" above</a>. See 
        <a href="http://fhem.de/commandref.html#get">commandref#get</a> for more info about 
        the get command.
    </ul>
    <br>
</ul>

=end html

=cut

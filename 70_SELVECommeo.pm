package main;
use strict;
use warnings;
use MIME::Base64 qw( decode_base64 encode_base64 );

my %SELVECommeo_gets = (
    "getInfo"       => ["selve.GW.device.getInfo",":noArg"],
    "getValues"     => ["selve.GW.device.getValues",":noArg"]
);

my %SELVECommeo_sets = (
    "save"          => ["selve.GW.device.save",":noArg"],
    "setFunction"   => ["selve.GW.device.setFunction",":0,1,2,3,4,5,6,7,8,9"],
    "setLabel"      => ["selve.GW.device.setLabel",":textField"],
    "setType"       => ["selve.GW.device.setType",":0,1,2,3,4,5,6,7,8,9,10,11"],
    "delete"        => ["selve.GW.device.delete",":noArg"],
    "writeManual"   => ["selve.GW.device.writeManual",""],

	"up"				=> ["selve.GW.command.device:1",":noArg"],
    "open"              => ["selve.GW.command.device:1",":noArg"],
    "on"                => ["selve.GW.command.device:1",":noArg"],
    "down"              => ["selve.GW.command.device:2",":noArg"],
	"closed"			=> ["selve.GW.command.device:2",":noArg"],
	"stop"				=> ["selve.GW.command.device:0",":noArg"],
    "off"               => ["selve.GW.command.device:0",":noArg"],
    "Pos1"				=> ["selve.GW.command.device:3",":noArg"],
	"Pos2"				=> ["selve.GW.command.device:5",":noArg"],
    "SavePos1"			=> ["selve.GW.command.device:4",":noArg"],
    "SavePos2"			=> ["selve.GW.command.device:6",":noArg"],
    "position"          => ["selve.GW.command.device:7",":0,10,20,30,40,50,60,70,80,90,100"],
    "reinit"            => ["reinit",":noArg"]
);

my %positions = (
  "open" => 0,
  "closed" => 100,
  "half" => 50);

sub SELVECommeo_Initialize($) {
    my ($hash) = @_;

    $hash->{DefFn}      = 'SELVECommeo_Define';
    $hash->{UndefFn}    = 'SELVECommeo_Undef';
    $hash->{DeleteFn}   = 'SELVECommeo_Delete';
    $hash->{SetFn}      = 'SELVECommeo_Set';
    $hash->{GetFn}      = 'SELVECommeo_Get';
    $hash->{AttrFn}     = 'SELVECommeo_Attr';
    $hash->{ReadFn}     = 'SELVECommeo_Read';
	$hash->{ParseFn}	= 'SELVECommeo_Parse';
	
	$hash->{Match}     = "^SELVECommeo@@.*";

    $hash->{AttrList} = "type:normal,HomeKit commandType:manual,automatic userReadings alarm_mask " . $readingFnAttributes;
}

sub SELVECommeo_Define($$) {
    my ($hash, $def) = @_;
    my @param = split('[ \t]+', $def);
	
	my $name = $param[0];
    
    if(int(@param) != 3) {
        return "usage: define <name> SELVECommeo <AktorID>";
    }
    
	$hash->{AktorID} = $param[2];
	$hash->{maskdec} = 2 ** $param[2];
    my $Mask64 = encode_base64(pack("L2",$hash->{maskdec}));
	$Mask64 =~ s/\r//;
	$Mask64 =~ s/\n//;
	Log3 $hash, 5, "SELVECommeo ($name): MASK: $Mask64";
	$hash->{maskbase64} = $Mask64;

	$attr{$name}{webCmd} = "up:stop:down:Pos1:Pos2:SavePos1:SavePos2:position";
	$attr{$name}{devStateIcon} = 'open:fts_shutter_10:closed closed:fts_shutter_100:open half:fts_shutter_50:closed drive-up:fts_shutter_up@red:stop drive-down:fts_shutter_down@red:stop position-100:fts_shutter_10:open position-90:fts_shutter_10:closed position-80:fts_shutter_20:closed position-70:fts_shutter_30:closed position-60:fts_shutter_40:closed position-50:fts_shutter_50:closed position-40:fts_shutter_60:open position-30:fts_shutter_70:open position-20:fts_shutter_80:open position-10:fts_shutter_90:open position-0:fts_shutter_100:closed';
    $attr{$name}{"type"} = "HomeKit";

    $modules{SELVECommeo}{defptr}{$param[2]} = $hash;
    
	AssignIoPort($hash);
    #Log3 undef, 2, Dumper($hash);
    return undef;
}

sub SELVECommeo_Delete($$) {
    my ( $hash, $name ) = @_;
    $modules{SELVECommeo}{defptr}{$hash->{AktorID}} = undef;
    return undef;
}

sub SELVECommeo_Parse($$) {
	my ($gwhash, $msg) = @_;
    my ($cmd,$devid) = split(/:/, $msg);
    $cmd =~ s/SELVECommeo@@//;
   
    my $DevResp = '';
    my $key = '';
    my $State = '';
    
    #Log3 $hash, 2, "DEFS: " . Dumper(%defs);
    #Log3 $hash, 2, "Module: " . Dumper($modules{SELVECommeo});
    
    my $hash = $modules{SELVECommeo}{defptr}{$devid};
    if(!$hash)
    {
        DoTrigger("global","UNDEFINED SELVECommeo_$devid SELVECommeo $devid");
        Log3 $hash, 3, "SELVECommeo UNDEFINED, code $devid";
        return "UNDEFINED SELVECommeoDeviceID $devid $msg";
    }

    my $name = $hash->{NAME};
    Log3 $hash, 3, "SELVECommeo ($name): PARSE CALLED: $name, cmd: $cmd, AktorID: $devid";

    my $data = $data{SELVEresponse};

    if($cmd eq "selve.GW.device.getInfo")
    {
        my @KonfInfo = ("Unbekannte Konfiguration", "Rollladen", "Jalousie", "Markise", "Schaltaktor", "Dimmer", "Nachtlicht Aktor",
                                    "Dämmerlicht Aktor", "Heizung", "Kühlgerät", "Schaltaktor (Tagbetrieb)", "Gateway");
        my @StateInfo = ("AktorID wird nicht genutzt", "AktorID wird genutzt", "AktorID wird temporär genutzt", "AktorID wurde früher genutzt. Durch ein Löschvorgang wird sie derzeitig nicht mehr genutzt.");
                   
        my $response = "AktorID: " . $data->{array}->{int}[0] . " | Funkadresse: " . $data->{array}->{int}[1] . " | ";
                    $response .= "AktorName: " . $data->{array}->{string}[1] . " | Konfig: " . $KonfInfo[$data->{array}->{int}[2]] . " | ";
                    $response .= "Status: " . $StateInfo[$data->{array}->{int}[3]];
                    
        $hash->{DevInfo} = $response;
        if ($hash->{type} ne $data->{array}->{int}[2])
        {
            $hash->{type} = $data->{array}->{int}[2];
            if ($hash->{type} >= 1 && $hash->{type} <= 3) {
                $attr{$name}{webCmd} = "up:stop:down:Pos1:Pos2:SavePos1:SavePos2:position";
                $attr{$name}{devStateIcon} = 'open:fts_shutter_10:closed closed:fts_shutter_100:open half:fts_shutter_50:closed drive-up:fts_shutter_up@red:stop drive-down:fts_shutter_down@red:stop position-100:fts_shutter_10:open position-90:fts_shutter_10:closed position-80:fts_shutter_20:closed position-70:fts_shutter_30:closed position-60:fts_shutter_40:closed position-50:fts_shutter_50:closed position-40:fts_shutter_60:open position-30:fts_shutter_70:open position-20:fts_shutter_80:open position-10:fts_shutter_90:open position-0:fts_shutter_100:closed';
            } elsif ($hash->{type} >= 4 && $hash->{type} <= 10) {
                $attr{$name}{webCmd} = "on:off";
                $attr{$name}{devStateIcon} = 'on:on:off off:off:on';
            }
        }
    } elsif ($cmd eq 'selve.GW.device.getValues' or $cmd eq 'selve.GW.event.device')
    {
        my @ModeInfo = ("Unbekannter Tageszustand", "Nachtmodus", "Morgendämmerung", "Tagmodus", "Abenddämmerung");
        my @StateInfo = ("Unbekannter Zustand", "Aktor ist gestoppt", "Aktor fährt hoch", "Aktor fährt runter");
                    
        my $StateAktuell = ceil($data->{array}->{int}[2] * 100 / 65535);
        $StateAktuell .= "% geschlossen";
        my $StateTarget = $data->{array}->{int}[3];
        my $Flags = $data->{array}->{int}[4];
                   
        my $response = "AktorID: " . $data->{array}->{int}[0] . " | Status: " . $StateInfo[$data->{array}->{int}[1]] . " | ";
        $response .= "Aktueller Wert: " . $data->{array}->{int}[2] . " | Zielwert: " . $data->{array}->{int}[3] . " | ";
        $response .= "Zustand: " . $data->{array}->{int}[4] . " | DayMode: " . $ModeInfo[$data->{array}->{int}[5]] . " | ";
        $response .= "Name: " . ($cmd eq 'selve.GW.device.getValues' ? $data->{array}->{string}[1] : $data->{array}->{string});
                    
        $hash->{DevValues} = $response;
        readingsBeginUpdate($hash);
        readingsBulkUpdate($hash, "drive", $StateInfo[$data->{array}->{int}[1]]);
        my $position = ceil($data->{array}->{int}[2] * 100 / 65535);
        readingsBulkUpdate($hash, "pct", 100-$position);
        readingsBulkUpdate($hash, "position", $position);
        my $target_position = ceil($data->{array}->{int}[3] * 100 / 65535);
        readingsBulkUpdate($hash, "target_position", $target_position);
        my $flags = $data->{array}->{int}[4];
        readingsBulkUpdate($hash, "flags", $flags);
        my $mask = 1;
        my @alerts = ();
        my $alarm_mask = AttrVal($name,"alarm_mask", 0b1111011111 );
        my $flag;
        for $flag (qw(unreachable overload obstacle signal lost_sensor automatic lost_gateway wind rain frost)) {
            readingsBulkUpdate($hash, $flag, $flags & $mask ? "on": "off");
            push @alerts, $flag if $flags & $mask & $alarm_mask;
            $mask <<= 1;
        }
        readingsBulkUpdate($hash, "alarm", join(",",@alerts)); 
        readingsBulkUpdate($hash, "day_mode", $ModeInfo[$data->{array}->{int}[5]]);
        $hash->{"AktorName"} = $cmd eq 'selve.GW.device.getValues' ? $data->{array}->{string}[1] : $data->{array}->{string};
        my $drivestate = $data->{array}->{int}[1];
        my $state;
        if ($drivestate == 0) {
            $state = "unknown";
        } elsif ($drivestate == 1) {
            readingsBulkUpdate($hash, "motor", "stop");
            #Runden der Position auf volle 10%-Schritte für das Icon
            my $newpos = int($position/10+0.5)*10;
            $newpos = 0 if($newpos < 0);
            $newpos = 100 if ($newpos > 100);

            #   position in text umwandeln
            my %rhash = reverse %positions;
            if (defined($rhash{$newpos}))
            {
               $state = $rhash{$newpos};
            # ich kenne keinen Text für die Position, also als position-nn anzeigen
            } else {
#wenn ich die Position als Zahl anzeige muss ich sie bei HomeKit noch schnell umwandeln
                if (AttrVal($name,"type","normal") eq "HomeKit")    {
                    $newpos = 100-$newpos
                }
                $state = "position-$newpos";
            }
        } elsif ($drivestate == 2) {
            readingsBulkUpdate($hash, "motor", "up");
            $state = "drive-up";
            readingsBulkUpdate($hash,"last_drive",$state);
        } elsif ($drivestate == 3) {
            readingsBulkUpdate($hash, "motor", "down");
            $state = "drive-down";
            readingsBulkUpdate($hash,"last_drive",$state);
        }
        readingsBulkUpdate($hash,"state",$state);

        readingsEndUpdate($hash, 1); # Notify is done by Dispatch
    }
        
    return $name; 
}

sub SELVECommeo_Undef($$) {
    my ($hash, $arg) = @_; 
    # nothing to do
    return undef;
}

sub SELVECommeo_Get($@) {
	my ($hash, $name, @param) = @_;
	
    return '"get SELVE" needs at least one argument' if (@param < 1);
	
    my $opt = shift @param;
	
    if(!$SELVECommeo_gets{$opt}) {
        my @setparams = ();
        my $key;
        for $key (keys %SELVECommeo_gets) {
            unshift @setparams, $key . $SELVECommeo_gets{$key}[1];
        }
        return "Unknown argument $opt, choose one of " . join(" ", @setparams);
    }
    
    my $cmd = $SELVECommeo_gets{$opt}[0];
	
    Log3 $hash, 3, "SELVECommeo ($name): GET-CMD: " . $cmd . " ; " . $hash->{AktorID} . " via " . $hash->{IODev}->{NAME} ;
    
    $hash->{"lastCommand"} = $cmd;
    $hash->{"IODev"}->{"lastCommand"} = $cmd;
    $hash->{"IODev"}->{"lastAktorID"} = $hash->{"AktorID"};
 	
    unshift(@param, $hash->{AktorID}); # einfügen AktorID
    unshift(@param, $cmd); # einfügen Commando
    IOWrite($hash, $cmd, @param);
    
 	return undef;
}

sub SELVECommeo_Set($@) {
	my ($hash, $name, @param) = @_;
	
	return '"set SELVECommeo" needs at least one argument' if (int(@param) < 1);
	
	my $opt = shift @param;
	
	if(!$SELVECommeo_sets{$opt}) {
        my @setparams = ();
        my $key;
		for $key (keys %SELVECommeo_sets) {
            unshift @setparams, $key . $SELVECommeo_sets{$key}[1];
        }
        return "Unknown argument $opt, choose one of " . join(" ", @setparams);
	}
	
    my $cmd = $SELVECommeo_sets{$opt}[0];

    Log3 $hash, 5, "SELVECommeo ($name): SET-CMD: " . $cmd . " ; " . $hash->{AktorID} . " via " . $hash->{IODev}->{NAME} ;

    $hash->{"lastCommand"} = $cmd;
    $hash->{"IODev"}->{"lastCommand"} = $cmd;
    $hash->{"IODev"}->{"lastAktorID"} = $hash->{"AktorID"};

	if($cmd =~ "selve.GW.command.device.*")
    {
        if ($opt eq "open" or "$opt" eq "up")
            {
                readingsSingleUpdate($hash,"state","drive-up",1)
            }
        elsif ($opt eq "closed" or "$opt" eq "down")
            {
                readingsSingleUpdate($hash,"state","drive-down",1)
            }
        elsif ($opt eq "position" or "$opt" eq "Pos1" or "$opt" eq "Pos2")
            {
                readingsSingleUpdate($hash,"state","drive",1)
            }
        elsif ($opt eq "stop")
            {
                readingsSingleUpdate($hash,"state","stop",1)
            }
   
		if($cmd =~ "selve.GW.command.device:.*")
        {
			my @splitArray = split(':', $cmd);
			if(@splitArray > 1) {
                if ($splitArray[1] == 7) 
                {
                    if (@param != 1)
                    {
                        return "set position needs an argument";
                    } else {
                        $param[0] = ceil(($attr{$name}{type} eq "HomeKit" ?
                                        (100-$param[0]) : $param[0]) * 65535 / 100);
                    }
                } else {
                    if (@param != 0)
                    {
                        return "set $opt may not have arguments";
                    } else {
                        $param[0] = 0;
                    }
                }
                unshift(@param, 1); # Type
				unshift(@param, $splitArray[1]);  # einfügen Kommando  
				$cmd = $splitArray[0];
			}
		}
		
		unshift(@param, $hash->{AktorID}); # einfügen AktorID
		unshift(@param, $cmd); # einfügen Commando
        Log3 $hash, 5, "SELVECommeo ($name): CMD: $cmd with param: " . @param;
		IOWrite($hash, $cmd, @param);
    } elsif($cmd eq "reinit") {
        AssignIoPort($hash);
    } 
	
	return undef;
}


sub SELVECommeo_Attr(@) {
	my ($cmd,$name,$attr_name,$attr_value) = @_;
	Log3 undef, 5, "SELVECommeo ($name): CMD: $cmd ; ATTRNAME: $attr_name ; ATTRVALUE: $attr_value";
    
    #Auswertung von HomeKit und Logo - from 44_ROLLO.pm
    if($cmd eq "set") {
        if ($attr_name eq "type")
        {
            #auslesen des aktuellen Icon, wenn es nicht gesetzt ist, oder dem default entspricht, dann neue Zuweisung vornehmen
            my $iconNormal  = 'open:fts_shutter_10:closed closed:fts_shutter_100:open half:fts_shutter_50:closed drive-up:fts_shutter_up@red:stop drive-down:fts_shutter_down@red:stop position-100:fts_shutter_100:open position-90:fts_shutter_80:closed position-80:fts_shutter_80:closed position-70:fts_shutter_70:closed position-60:fts_shutter_60:closed position-50:fts_shutter_50:closed position-40:fts_shutter_40:open position-30:fts_shutter_30:open position-20:fts_shutter_20:open position-10:fts_shutter_10:open position-0:fts_shutter_10:closed';
            my $iconHomeKit = 'open:fts_shutter_10:closed closed:fts_shutter_100:open half:fts_shutter_50:closed drive-up:fts_shutter_up@red:stop drive-down:fts_shutter_down@red:stop position-100:fts_shutter_10:open position-90:fts_shutter_10:closed position-80:fts_shutter_20:closed position-70:fts_shutter_30:closed position-60:fts_shutter_40:closed position-50:fts_shutter_50:closed position-40:fts_shutter_60:open position-30:fts_shutter_70:open position-20:fts_shutter_80:open position-10:fts_shutter_90:open position-0:fts_shutter_100:closed';
            my $iconAktuell = $attr{$name}{devStateIcon};
            if (($attr_value eq "HomeKit") && (($iconAktuell eq $iconNormal) || ($iconAktuell eq ""))) {
                $attr{$name}{devStateIcon} = $iconHomeKit;
            }
            if (($attr_value eq "normal") && (($iconAktuell eq $iconHomeKit) || ($iconAktuell eq ""))) {
                $attr{$name}{devStateIcon} = $iconNormal;
            }
        }
	}
	return undef;
}

1;

=pod
=begin html

<a name="SELVECommeo"></a>
<h3>SELVECommeo</h3>
<ul>
    <i>SELVEcommeo</i> defines a SELVE device with Commeo protocol
    <br><br>
    <a name="SELVECommeoDefine"></a>
    <b>Define</b>
    <ul>
        <code>define <name> SELVECommeo <AktorID></code>
        <br><br>
        Example: <code>define shutter1 SELVECommeo 1</code>
        <br><br>
		AktorID (0 is channel number 1)
    </ul>
    <br>
    
    <a name="SELVECommeoSet"></a>
    <b>Set</b><br>
    <ul>
        <li><b>save</b></li>
        <li><b>setFunction</b> - I would not mess with this...</li>
        <li><b>setLabel</b> - change aktor name</li>
        <li><b>setType</b> - I would not mess with this...</li>
        <li><b>delete</b> - delete shutter from gateway - no questions asked</li>
        <li><b>writeManual</b></li>
        <li>Movement commands:
        <ul>
        <li><b>up/open/on</b></li> - drive up or turn on
        <li><b>down/closed/off</b></li> - drive down or turn off
        <li><b>stop</b></li>
        <li><b>Pos1</b></li>
        <li><b>Pos2</b></li>
        </ul></li>
        <li><b>SavePos1</b> - save current position as Pos1</li>
        <li><b>SavePos2</b> - save current position as Pos2</li>
        <li><b>position</b> - drive shutter to indicated position (interpretation depends an "type")</li>
        <li><b>reinit</b> - reassign IO port</li>
    </ul>
    <br>

    <a name="SELVECommeoGet"></a>
    <b>Get</b><br>
    <ul>
        <li><b>getInfo</b> - Read info from device (visible as Internal)</li>
        <li><b>getValues</b> - Read device state (sets Internal and Readings)</li>
    </ul>
    <br>

    <b>Attributes</b><br />
    <ul>
        <li><b>type</b> - normal/HomeKit - changes interpretation of position
        </li>
    </ul>
    <br />

    <b>Internals</b><br />
    <ul>
        <li><b>AktorID</b> - SELVE AktorID (starting from 0)</li>
        <li><b>AktorName</b> - name as reported by device</li>
        <li><b>DevValues</b> - last status response from device (formatted)</li>
        <li><b>DevInfo</b> - last response to getInfo command (formatted)</li>
        <li><b>LastCommand</b> - last command sent to device</li>
        <li><b>mask</b> - 2 ** AktorID</li>
        <li><b>maskdec</b> - mask bas64 coded</li>
        <li><b>type</b> - type of actor
    </ul>
    <br />

    <b>Generated Readings/Events</b><br />
    <ul>
        <li><b>drive</b> - Shows current drive command</li>
        <li><b>last_drive</b> - Shows direction of last drive (drive-up/drive-down)</li>
        <li><b>pct</b> - Current position as reported by the shutter (100=open, 0=closed)</li>
        <li><b>position</b> - Current position as reported by the shutter (0=open, 100=closed)</li>
        <li><b>target_position</b> - target position of current drive command</li>
        <li><b>flags</b> - Status of the device (bitmask) - also broken down into the following readings:
        <ul>
        <li><b>unreachable</b> - on/off (1)</li>
        <li><b>overload</b> - on/off (2)</li>
        <li><b>obstacle</b> - on/off (4)</li>
        <li><b>signal</b> - on/off (8)</li>
        <li><b>lost_sensor</b> - on/off (16)</li>
        <li><b>automatic</b> - on/off (32)</li>
        <li><b>lost_gateway</b> - on/off (64)</li>
        <li><b>wind</b> - on/off (128)</li>
        <li><b>rain</b> - on/off (256)</li>
        <li><b>frost</b> - on/off (512)</li>
        </ul>
        <li><b>alarm</b> - comma separated list of current alarms (from the list above except "automatic")</li>
        <li><b>alarm_mask</b> - bitmask of alarms to be included in "alarm" (add values for alarms to be included)</li>
        <li><b>day_mode</b> - Daymode (string)</li>
        <li><b>state</b> - state for icon: open,closed,half,position-?? (rounded to the nearest multiple of ten),drive-up,drive-down (is affected by the setting of "type")</li>
    </ul>
    
</ul>

=end html

=cut
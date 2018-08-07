package main;
use strict;
use warnings;
use MIME::Base64 qw( decode_base64 encode_base64 );

my %SELVEsensor_gets = (
    "getInfo"       => ["selve.GW.sensor.getInfo",":noArg"],
    "getValues"     => ["selve.GW.sensor.getValues",":noArg"]
);

my %SELVEsensor_sets = (
    "setLabel"      => ["selve.GW.sensor.setLabel",":textField"],
    "delete"        => ["selve.GW.sensor.delete",":noArg"],
    "writeManual"   => ["selve.GW.sensor.writeManual",""],
    "clear"         => ["clear",":noArg"],
    "reinit"        => ["reinit",":noArg"]
);

sub SELVEsensor_Initialize($) {
    my ($hash) = @_;

    $hash->{DefFn}      = 'SELVEsensor_Define';
    $hash->{UndefFn}    = 'SELVEsensor_Undef';
    $hash->{DeleteFn}   = 'SELVEsensor_Delete';
    $hash->{SetFn}      = 'SELVEsensor_Set';
    $hash->{GetFn}      = 'SELVEsensor_Get';
    $hash->{AttrFn}     = 'SELVEsensor_Attr';
    $hash->{ReadFn}     = 'SELVEsensor_Read';
	$hash->{ParseFn}	= 'SELVEsensor_Parse';
	
	$hash->{Match}     = "^SELVEsensor@@.*";

    $hash->{AttrList} = "verbose room " . $readingFnAttributes;
}

sub SELVEsensor_Define($$) {
    my ($hash, $def) = @_;
    my @param = split('[ \t]+', $def);
	
	my $name = $param[0];
    
    if(int(@param) < 3) {
        return "too few parameters: define <name> SELVEsensor <SensorID>";
    }    
	$hash->{AktorID} = $param[2];
	$hash->{maskdec} = 2 ** $param[2];
    my $Mask64 = encode_base64(pack("L2",$hash->{maskdec}));
	$Mask64 =~ s/\r//;
	$Mask64 =~ s/\n//;
	Log3 $hash, 5, "MASK: $Mask64";
	$hash->{maskbase64} = $Mask64;

	$attr{$name}{webCmd} = "";

    $modules{SELVEsensor}{defptr}{$param[2]} = $hash;
    
	AssignIoPort($hash);

    return undef;
}

sub SELVEsensor_Delete($$) {
    my ( $hash, $name ) = @_;
    $modules{SELVEsensor}{defptr}{$hash->{AktorID}} = undef;
    return undef;
}

sub SELVEsensor_Parse($$) {
	my ($gwhash, $msg) = @_;
    my ($cmd,$devid) = split(/:/, $msg);
    $cmd =~ s/SELVEsensor@@//;
   
    my $DevResp = '';
    my $key = '';
    my $State = '';
    
    #Log3 $hash, 2, "DEFS: " . Dumper(%defs);
    #Log3 $hash, 2, "Module: " . Dumper($modules{SELVEsensor});
    
    my $hash = $modules{SELVEsensor}{defptr}{$devid};
    if(!$hash)
    {
        DoTrigger("global","UNDEFINED SELVEsensor_$devid SELVEsensor $devid");
        Log3 $hash, 3, "SELVEsensor UNDEFINED, code $devid";
        return "UNDEFINED SELVEsensorDeviceID $devid $msg";
    }

    my $name = $hash->{NAME};
    Log3 $hash, 3, "PARSE CALLED: $name, cmd: $cmd, AktorID: $devid";

    my $data = $data{SELVEresponse};

    if($cmd eq "selve.GW.sensor.getInfo")
    {
        my $response = "SensorID: " . $data->{array}->{int}[0] . " | Funkadresse: " . $data->{array}->{int}[1] . " | ";
        $response .= "SensorName: " . $data->{array}->{string}[1];
        $hash->{DevInfo} = $response;
    } elsif ($cmd eq 'selve.GW.sensor.getValues' or $cmd eq 'selve.GW.event.sensor')
    {
        my @sensorStateInfo = ("invalid", "valid", "valid", "lost", "test", "service");
        my $response = "SensorID: " . $data->{array}->{int}[0] . " | Status: " . $sensorStateInfo[$data->{array}->{int}[5]];
                    
        $hash->{DevValues} = $response;
        readingsBeginUpdate($hash);
        readingsBulkUpdate($hash,"windalarm",($data->{array}->{int}[1] == 1) ? "ok" : "wind") if $data->{array}->{int}[1] > 0;
        if ($data->{array}->{int}[2] > 0)
        {
            readingsBulkUpdate($hash,"rainalarm",($data->{array}->{int}[2] == 1) ? "ok" : "rain") ;
        } else {
            readingsDelete($hash,"rainalarm");
        }
        my @tempStatus = ("ok", "frost", "warm");
        readingsBulkUpdate($hash,"tempalarm",$tempStatus[$data->{array}->{int}[3]-1]) if $data->{array}->{int}[3] > 0;
        readingsBulkUpdate($hash,"light",$data->{array}->{int}[4]-1) if $data->{array}->{int}[4] > 0;
        my @lightStatus = ("dark", "dim", "normal", "sunny");
        readingsBulkUpdate($hash,"lightalarm",$lightStatus[$data->{array}->{int}[4]-1]) if $data->{array}->{int}[4] > 0;
        readingsBulkUpdate($hash,"battery","ok") if $data->{array}->{int}[5] == 1;
        readingsBulkUpdate($hash,"battery","low") if $data->{array}->{int}[5] == 2;
        readingsBulkUpdate($hash,"state",$sensorStateInfo[$data->{array}->{int}[5]]);
        readingsBulkUpdate($hash,"temperature",$data->{array}->{int}[6] * 0.5 - 40.0) if $data->{array}->{int}[6] >= 0;
        readingsBulkUpdate($hash,"wind",$data->{array}->{int}[7] * 0.5) if $data->{array}->{int}[7] >= 0;
        my @brightvals = ();
        readingsBulkUpdate($hash,"sun1",$data->{array}->{int}[8] * 500), push(@brightvals, $data->{array}->{int}[8] * 500)
            if $data->{array}->{int}[8] >= 0;
        readingsBulkUpdate($hash,"lightsensor",$data->{array}->{int}[9] * 4.0), push(@brightvals, $data->{array}->{int}[9] * 4.0) 
            if $data->{array}->{int}[9] >= 0;
        readingsBulkUpdate($hash,"sun2",$data->{array}->{int}[10] * 500), push(@brightvals, $data->{array}->{int}[10] * 500) 
            if $data->{array}->{int}[10] >= 0;
        readingsBulkUpdate($hash,"sun3",$data->{array}->{int}[11] * 500), push(@brightvals, $data->{array}->{int}[11] * 500)
            if $data->{array}->{int}[11] >= 0;
        if (@brightvals > 0){
            my @brightvals = sort { $a <=> $b } @brightvals;
            readingsBulkUpdate($hash,"brightness",$brightvals[-1]);
        }

        readingsEndUpdate($hash, 1); # Notify is done by Dispatch
    }
        
    return $name; 
}

sub SELVEsensor_Undef($$) {
    my ($hash, $arg) = @_; 
    # nothing to do
    return undef;
}

sub SELVEsensor_Get($@) {
	my ($hash, $name, @param) = @_;
	
    return '"get SELVE" needs at least one argument' if (@param < 1);
	
    my $opt = shift @param;
	
    if(!$SELVEsensor_gets{$opt}) {
        my @setparams = ();
        my $key;
        for $key (keys %SELVEsensor_gets) {
            unshift @setparams, $key . $SELVEsensor_gets{$key}[1];
        }
        return "Unknown argument $opt, choose one of " . join(" ", @setparams);
    }
    
    my $cmd = $SELVEsensor_gets{$opt}[0];
	
    Log3 $hash, 3, "GET-CMD: " . $cmd . " ; " . $hash->{AktorID} . " via " . $hash->{IODev}->{NAME} ;
    
    $hash->{"lastCommand"} = $cmd;
    $hash->{"IODev"}->{"lastCommand"} = $cmd;
    $hash->{"IODev"}->{"lastAktorID"} = $hash->{"AktorID"};
 	
    unshift(@param, $hash->{AktorID}); # einfügen AktorID
    unshift(@param, $cmd); # einfügen Commando
    IOWrite($hash, $cmd, @param);
    
 	return undef;
}

sub SELVEsensor_Set($@) {
	my ($hash, $name, @param) = @_;
	
	return '"set SELVEsensor" needs at least one argument' if (int(@param) < 1);
	
	my $opt = shift @param;
	
	if(!$SELVEsensor_sets{$opt}) {
        my @setparams = ();
        my $key;
		for $key (keys %SELVEsensor_sets) {
            unshift @setparams, $key . $SELVEsensor_sets{$key}[1];
        }
        return "Unknown argument $opt, choose one of " . join(" ", @setparams);
	}
	
    my $cmd = $SELVEsensor_sets{$opt}[0];

    Log3 $hash, 5, "SET-CMD: " . $cmd . " ; " . $hash->{AktorID} . " via " . $hash->{IODev}->{NAME} ;

    $hash->{"lastCommand"} = $cmd;
    $hash->{"IODev"}->{"lastCommand"} = $cmd;
    $hash->{"IODev"}->{"lastAktorID"} = $hash->{"AktorID"};

	if($cmd =~ "selve.GW.sensor.setLabel")
    {
		if (@param != 1)
            {
                return "set label needs an argument";
            }
		unshift(@param, $hash->{AktorID}); # einfügen AktorID
		unshift(@param, $cmd); # einfügen Commando
        Log3 $hash, 5, "CMD: $cmd with param: " . @param;
		IOWrite($hash, $cmd, @param);
    } elsif($cmd eq "reinit") {
        AssignIoPort($hash);
    } elsif($cmd eq "clear") {
        delete $hash->{"lastCommand"};
        delete $hash->{"DevValues"};
        delete $hash->{"DevInfo"};
    } 
	
	return undef;
}


sub SELVEsensor_Attr(@) {
	my ($cmd,$name,$attr_name,$attr_value) = @_;
	Log3 undef, 5, "CMD: $cmd ; NAME: $name ; ATTRNAME: $attr_name ; ATTRVALUE: $attr_value";
    
	return undef;
}

1;

=pod
=begin html

<a name="SELVEsensor"></a>
<h3>SELVEsensor</h3>
<ul>
    <i>SELVEsensor</i> defines a SELVE sensor
    <br><br>
    This modul is used to receive data from a SELVE sensor ("Markisensensorik").
    <br><br>
    <a name="SELVEsensorDefine"></a>
    <b>Define</b>
    <ul>
        <code>define <name> SELVEsensor &lt;SensorID&gt;</code>
        <br><br>
        Example: <code>define Markisensensor SELVEsensor 0</code>
        <br><br>
		SensorID (0 is channel number 1)
    </ul>
    <br>
    
    <a name="SELVEsensorSet"></a>
    <b>Set</b><br>
    <ul>
        <li><b>setLabel</b> - change sensor name</li>
        <li><b>delete</b> - delete sensor from gateway - no questions asked</li>
        <li><b>writeManual</b></li>
        <li><b>reinit</b> - reassign IO port</li>
    </ul>
    <br>

    <a name="SELVEsensorGet"></a>
    <b>Get</b><br>
    <ul>
        <li><b>getInfo</b> - Read info from sensor (visible as Internal)</li>
        <li><b>getValues</b> - Read sensor state (sets Readings)</li>
    </ul>
    <br>

    <b>Internals</b><br />
    <ul>
        <li><b>AktorID</b> - SELVE SensorID (starting from 0)</li>
        <li><b>AktorName</b> - name as reported by sensor</li>
        <li><b>DevInfo</b> - last response to getInfo command (formatted)</li>
        <li><b>LastCommand</b> - last command sent to sensor</li>
        <li><b>mask</b> - 2 ** AktorID</li>
        <li><b>maskdec</b> - mask bas64 coded</li>
    </ul>
    <br />

    <b>Generated Readings/Events</b><br />
    <ul>
        <li><b>windalarm</b> - Status of wind: ok/wind</li>
        <li><b>rainalarm</b> - Status of rain: ok/rain</li>
        <li><b>tempalarm</b>- Status of temperature: ok/frost/warm</li>
        <li><b>lightalarm</b> - Status of light: dark/dim/normal/sunny</li>
        <li><b>light</b> - Status of light as number 0-3</li>
        <li><b>battery</b> - Status of battery: ok/low</li>
        <li><b>state</b> - Status of sensor: invalid/valid/lost/test</li>
        <li><b>temperature</b> - Value of temperatur sensor (Celsius)</li>
        <li><b>wind</b> - Speed of wind (m/s)</li>
        <li><b>sun1</b> - Value of 1st sun sensor (Lux)</li>
        <li><b>sun2</b> - Value of 2nd sun sensor (Lux)</li>
        <li><b>sun3</b> - Value of 3rd sun sensor (Lux)</li>
        <li><b>brightness</b> - Value of brightness sensor (Lux)</li>
</ul>

=end html

=cut
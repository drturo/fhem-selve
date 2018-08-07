package main;
use strict;
use warnings;
use MIME::Base64 qw( encode_base64 );

my %SELVE_gets = (
	"getConfig"			=> "selve.GW.iveo.getConfig"
);

my %SELVE_sets = (
	"setLabel"			=> "setLabel",
	"setConfig"			=> "selve.GW.iveo.setConfig",
	"factoryReset"		=> "factoryReset",
	"commandTeach"		=> "selve.GW.iveo.commandTeach",
	"commandLearn"		=> "commandLearn",
	"commandManual"		=> "selve.GW.iveo.commandManual",
	"commandAutomatic"	=> "selve.GW.iveo.commandAutomatic",
	"up"				=> "selve.GW.iveo.commandManual:1",
	"down"				=> "selve.GW.iveo.commandManual:2",
	"stop"				=> "selve.GW.iveo.commandManual:0",
	"Pos1"				=> "selve.GW.iveo.commandManual:3",
	"Pos2"				=> "selve.GW.iveo.commandManual:4",
	"reinit"			=> "reinit"
);

sub SELVE_Initialize($) {
    my ($hash) = @_;

    $hash->{DefFn}      = 'SELVE_Define';
    $hash->{UndefFn}    = 'SELVE_Undef';
    $hash->{SetFn}      = 'SELVE_Set';
    $hash->{GetFn}      = 'SELVE_Get';
    $hash->{AttrFn}     = 'SELVE_Attr';
    $hash->{ReadFn}     = 'SELVE_Read';
	$hash->{ParseFn}	= 'SELVE_Parse';
	
	$hash->{Match}     = "^SELVE@@.*";


    $hash->{AttrList} =
          "webCmd devStateIcon room commandType:manual,automatic verbose "
        . $readingFnAttributes;
}

sub SELVE_Define($$) {
    my ($hash, $def) = @_;
    my @param = split('[ \t]+', $def);
	
	my $name = $param[0];
    
    if(int(@param) < 4) {
        return "too few parameters: define <name> SELVE <type> <iveoid>";
    }
    
    $hash->{name}  = $name;
    $hash->{type} = $param[2];
	$hash->{iveoid} = $param[3];
	$hash->{iveomaskdec} = 2 ** $param[3];
	my $iveoMask64 = encode_base64(pack("L2",$hash->{iveomaskdec}));
	$iveoMask64 =~ s/\r//;
	$iveoMask64 =~ s/\n//;
	Log3 $hash, 5, "IVEOMASK: $iveoMask64";
	$hash->{iveomaskbase64} = $iveoMask64;
	$attr{$name}{webCmd} = "up:stop:down:Pos1:Pos2";
	$attr{$name}{devStateIcon} = "down:fts_shutter_100 up:fts_window_2w stop:fts_shutter_50 Pos1:fts_shutter_20 Pos2:fts_shutter_80";
	AssignIoPort($hash);
    return undef;
}

sub SELVE_Parse($$) {
	my ($hash, $msg) = @_;
	my $name = $hash->{NAME};
	
	Log3 $hash, 5, "PARSE CALLED: $name";
	
	return $name;
}

sub SELVE_Undef($$) {
    my ($hash, $arg) = @_; 
    # nothing to do
    return undef;
}

sub SELVE_Get($@) {
	my ($hash, $name, @param) = @_;
	
	my $cnt = @param;
	my $rValue = "";
	
	return '"get SELVE" needs at least one argument' if ($cnt < 1);
	
	my $cmd = $param[0];
	
	if(!$SELVE_gets{$cmd}) {
		my @cList = keys %SELVE_gets;
		return "Unknown argument $cmd, choose one of " . join(" ", @cList);
	}
	
	return $rValue;
}

sub SELVE_Set($@) {
	my ($hash, $name, @param) = @_;
	
	return '"set SELVE" needs at least one argument' if (int(@param) < 1);
	
	my $opt = shift @param;
	
	if(!$SELVE_sets{$opt}) {
		my @cList = keys %SELVE_sets;
		return "Unknown argument $opt, choose one of " . join(" ", @cList);
	}
	
	readingsBeginUpdate($hash);
	readingsBulkUpdate($hash, "lastCommand", $opt);
	$hash->{STATE} = $opt;
	
	my $cmd = $SELVE_sets{$opt};
	
	Log3 $hash, 5, "SET-CMD: " . $cmd . " ; " . $hash->{iveomaskbase64};
	if($cmd =~ "selve.GW.iveo.commandManual.*") {
		if($cmd =~ "selve.GW.iveo.commandManual:.*") {
			my @splitArray = split(':', $cmd);
			Log3 $hash, 5, "SPLITARRAY: " . @splitArray;
			if(@splitArray > 1) {
				unshift(@param, $splitArray[1]);
				$cmd = $splitArray[0];
			}
		}
		my $commandType = AttrVal($name,"commandType","manual");
		Log3 $hash, 5, "COMMAND-TYPE: " . $commandType;
		if($commandType eq "automatic") {
			$cmd = "selve.GW.iveo.commandAutomatic";
		}
		unshift(@param, $hash->{iveomaskbase64});
		unshift(@param, $cmd);
		IOWrite($hash, $cmd, @param);
	} elsif($cmd eq "selve.GW.iveo.commandTeach") {
		unshift(@param, $hash->{iveoid});
		unshift(@param, $cmd);
		IOWrite($hash, $cmd, @param);
	} elsif($cmd eq "selve.GW.iveo.setConfig") {
		unshift(@param, $hash->{iveoid});
		unshift(@param, $cmd);
		IOWrite($hash, $cmd, @param);
	} elsif($cmd eq "reinit") {
		AssignIoPort($hash);
	}
    
	readingsEndUpdate($hash, 1);
	
	return undef;
}


sub SELVE_Attr(@) {
	my ($cmd,$name,$attr_name,$attr_value) = @_;
	#Log3 undef, 5, "CMD: $cmd ; NAME: $name ; ATTRNAME: $attr_name ; ATTRVALUE: $attr_value";
	#if($cmd eq "set") {
    #    if($attr_name eq "webCmd") {}
	#	elsif($attr_name eq "devStateIcon"){}
	#	elsif($attr_name eq "room"){}
	#	elsif($attr_name eq "commandType"){}
	#	elsif($attr_name eq "verbose") {}
	#	else {
	#	    return "Unknown attr $attr_name";
	#	}
	#}
	return undef;
}

1;

=pod
=begin html

<a name="SELVE"></a>
<h3>SELVE</h3>
<ul>
    <i>SELVE</i> implements the classical "SELVE World" as a starting point for module development. 
    You may want to copy 98_SELVE.pm to start implementing a module of your very own. See 
    <a href="http://www.fhemwiki.de/wiki/DevelopmentModuleIntro">DevelopmentModuleIntro</a> for an 
    in-depth instruction to your first module.
    <br><br>
    <a name="SELVEdefine"></a>
    <b>Define</b>
    <ul>
        <code>define <name> SELVE <type> <iveoid></code>
        <br><br>
        Example: <code>define shutter1 SELVE 1 1</code>
        <br><br>
        type (1 is an IVEO shutter, actual only this one is implemented)
		iveoid (1 is channel number 1)
		See <a href="http://fhem.de/commandref.html#define">commandref#define</a> 
        for more info about the define command.
    </ul>
    <br>
    
    <a name="SELVEset"></a>
    <b>Set</b><br>
    <ul>
        <code>set <name> <option> <value></code>
        <br><br>
        You can <i>set</i> any value to any of the following options. They're just there to 
        <i>get</i> them. See <a href="http://fhem.de/commandref.html#set">commandref#set</a> 
        for more info about the set command.
        <br><br>
        Options:
        <ul>
			<li><i>setLabel</i><br>
				For more information use SELVE XML Gateway description</li>
			<li><i>setConfig</i><br>
				For more information use SELVE XML Gateway description</li>
			<li><i>factoryReset</i><br>
				For more information use SELVE XML Gateway description</li>
			<li><i>commandTeach</i><br>
				For more information use SELVE XML Gateway description</li>
			<li><i>commandLearn</i><br>
				For more information use SELVE XML Gateway description</li>
			<li><i>commandManual</i><br>
				For more information use SELVE XML Gateway description</li>
			<li><i>commandLearn</i><br>
				For more information use SELVE XML Gateway description</li>
			<li><i>commandAutomatic</i><br>
				For more information use SELVE XML Gateway description</li>
			<li><i>up</i><br>
				For more information use SELVE XML Gateway description</li>
			<li><i>down</i><br>
				For more information use SELVE XML Gateway description</li>
			<li><i>stop</i><br>
				For more information use SELVE XML Gateway description</li>
			<li><i>Pos1</i><br>
				For more information use SELVE XML Gateway description</li>
			<li><i>Pos2</i><br>
				For more information use SELVE XML Gateway description</li>
        </ul>
    </ul>
    <br>

    <a name="SELVEget"></a>
    <b>Get</b><br>
    <ul>
        <code>getConfig <iveoid> <option></code>
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
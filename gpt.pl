#!/usr/bin/env perl
# Is chatgpt generated and will be used as a prototype.
# should be able to support environment variables, basic functions and aliases.
use strict;
use warnings;

# Subroutine to translate Fish functions to POSIX functions
sub convert_function {
    my ($line) = @_;
    if ($line =~ /^function\s+(\w+)/) {
        return "$1(){\n";  # Start of function
    } elsif ($line =~ /^end\s*$/) {
        return "\n}\n";    # End of function, ensure newline before closing brace
    }
    return $line;
}

# Subroutine to translate Fish variable setting to POSIX variable setting
sub convert_variable {
    my ($line) = @_;
    # Fish: set -gx var value (exported global variables)
    # POSIX: export var="value"
    if ($line =~ /^set\s+-gx\s+(\w+)\s+(.+)/) {
        my $var = $1;
        my $value = $2;

        # Only add quotes to variables not already inside quotes
        if ($value =~ /\$[A-Za-z_]+/) {
            # Ensure variables like $PATH are only quoted once
            return "export $var=$value\n";
        } else {
            return "export $var=\"$value\"\n"; # Normal variable assignment
        }
    }
    return $line;
}

# Subroutine to translate Fish aliases to POSIX shell aliases
sub convert_alias {
    my ($line) = @_;
    if ($line =~ /^alias\s+(\w+)\s+'(.+)'/) {
        return "alias $1='$2'\n";
    }
    return $line;
}

# Subroutine to add quotes to variable expansions in function bodies
sub quote_variables_in_function {
    my ($line) = @_;
    $line =~ s/(\$\w+)/"$1"/g;  # Quote any instance of $VAR in function bodies
    return $line;
}

# Main subroutine to convert Fish to POSIX shell
sub convert_fish_to_posix {
    my @lines = @_;
    my @output;

    foreach my $line (@lines) {
        chomp $line;

        # Ignore comments in Fish shell
        if ($line =~ /^\s*#/) {
            push @output, $line;
            next;
        }

        # Convert functions
        $line = convert_function($line);

        # Convert variables
        $line = convert_variable($line);

        # Convert aliases
        $line = convert_alias($line);

        # Add quotes to variables in function bodies
        $line = quote_variables_in_function($line);

        # Append the converted line to output
        push @output, $line;
    }

    return @output;
}

# Main script logic
if (@ARGV != 1) {
    die "Usage: $0 <fish_script.fish>\n";
}

my $fish_script = $ARGV[0];

# Read the Fish script
open my $fh, '<', $fish_script or die "Could not open '$fish_script' for reading: $!";
my @fish_lines = <$fh>;
close $fh;

# Convert the Fish script to POSIX shell
my @posix_lines = convert_fish_to_posix(@fish_lines);

# Print the POSIX shell script
foreach my $line (@posix_lines) {
    print $line;
}


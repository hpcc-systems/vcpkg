## This file generated by InlineX::C2XS (version 0.24) using Inline::C (version 0.73)

# Provides access to some gmp and mpfr macros/constants

package Math::MPFR::V;
use strict;
use warnings;

require Exporter;
*import = \&Exporter::import;
require DynaLoader;

our $VERSION = '3.34';
#$VERSION = eval $VERSION;
DynaLoader::bootstrap Math::MPFR::V $VERSION;

@Math::MPFR::V::EXPORT = ();
@Math::MPFR::V::EXPORT_OK = ();

sub dl_load_flags {0} # Prevent DynaLoader from complaining and croaking

1;

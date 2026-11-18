module m
implicit none
integer,parameter,public :: x=1
public :: x
contains

end module m
program main
use m
implicit none

print *,777
end program main

module m
implicit none
private
integer,parameter::secret=8
contains

end module m
program main
use m
implicit none

print *,777
print *,secret
end program main

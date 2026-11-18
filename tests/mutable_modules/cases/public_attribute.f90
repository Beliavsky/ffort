module state
private
integer,public::counter=2,vec(2)=1
end module
program main
use state
counter=7
vec(2)=9
print *,counter,vec(2)
end program

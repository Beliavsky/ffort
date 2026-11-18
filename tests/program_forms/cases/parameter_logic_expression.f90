program probe
implicit none
integer,parameter :: n=3
logical,parameter :: positive=n>0, bigger=n>4
if (positive.and..not.bigger) then
print*,n
end if
end program probe

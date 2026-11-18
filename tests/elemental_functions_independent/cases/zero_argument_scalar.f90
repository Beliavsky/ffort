program elemental_test
implicit none

print *,compute()
contains
elemental integer function compute() result(rr)

rr=8
end function compute

end program

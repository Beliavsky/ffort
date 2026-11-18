program p
implicit none

print *,random_seed()
contains
integer function random_seed() result(i)
i=42
end function
end program

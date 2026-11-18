implicit none
integer, parameter :: nlen = 5
character(len=nlen) :: s1(3) = [character(len=nlen) :: "one", "two", "three"]
character(len=nlen) :: s2(3) = ["one  ", "four ", "three"]
print*, s1, " " // s2, s1 == s2
end

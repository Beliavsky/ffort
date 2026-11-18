program p
implicit none
character(*),parameter::a=text()
print *,a
contains
function text() result(s)
character(1)::s
s="a"
end function
end program

program p
implicit none
print *,f()
contains
function f() result(leadz)
integer::leadz
leadz=17
end function
end program

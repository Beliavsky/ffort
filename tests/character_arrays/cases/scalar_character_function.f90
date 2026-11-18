program p
implicit none
print *,f()
contains
function f() result(r)
character(3)::r
r="a"//"bc"
end function
end

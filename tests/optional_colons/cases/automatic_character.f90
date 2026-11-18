program p
print '(a)',f(4)
contains
function f(n) result(v)
integer,intent(in)::n
character(n) v
v='abcd'
end function
end program

program p
integer::i
i=2
if('abcd'(bound(i):bound(i+1))/='bc') error stop 1
print *, 'pure bounds'
contains
pure integer function bound(x) result(y)
integer,intent(in)::x
y=x
end function
end program

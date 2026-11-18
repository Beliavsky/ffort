program p
if(kind('abc'(bad():bad()))/=1) error stop 1
print *, 'kind no evaluation'
contains
pure integer function bad() result(y)
error stop 9
y=1
end function
end program

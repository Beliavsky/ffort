program p
implicit none
integer,target::t(2)
integer,pointer::a(:)
integer::b(1)
t=1
a=>t
b=a([1])
end program

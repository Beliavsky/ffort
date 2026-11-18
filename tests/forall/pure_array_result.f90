program p
implicit none
integer::i,a(2,3)
forall(i=1:3) a(:,i)=pair(i)
print *,a
contains
pure function pair(x) result(b)
integer,intent(in)::x
integer::b(2)
b=[x,2*x]
end function
end program

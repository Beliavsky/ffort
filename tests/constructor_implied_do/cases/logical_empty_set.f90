program main
implicit none
integer::i
character(2)::x(2),y(0)
logical::a(2)
x=["aa","bb"]
a=[(all(y/=x(i)),i=1,size(x))]
print *,a,count(a)
end program

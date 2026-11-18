program p
integer::a(4)=[2,0,4,0],b(4)=-1
where(a/=0) b=f(a)
print *,b
contains
elemental integer function f(x)
integer,intent(in)::x
f=8/x
end function
end program

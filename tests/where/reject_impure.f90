program p
integer::a(2)=1
where(a>0) a=f(a)
contains
impure elemental integer function f(x)
integer,intent(in)::x
f=x
end function
end program

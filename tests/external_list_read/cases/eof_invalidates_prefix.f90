program p
implicit none
integer::u
integer::a,b,s
u=27
a=7
b=8
read(u,*,iostat=s)a,b
print *,a
end program

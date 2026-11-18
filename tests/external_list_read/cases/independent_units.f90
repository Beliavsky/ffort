program p
implicit none
integer::u
integer::v,a,b,c,s
u=27
v=28
read(u,*)a
read(v,*)b
backspace(u)
read(u,*)c
print *,a,b,c
end program

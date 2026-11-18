program p
implicit none
integer::u
character(3)::a(4)
integer::s
u=27
a=['one','two','tri','for']
read(u,*,iostat=s)a
if(s/=0)stop 1
print '(a)',a
end program

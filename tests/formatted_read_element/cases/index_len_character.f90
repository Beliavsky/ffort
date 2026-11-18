program p
implicit none
integer::u,ios
character(2)::a(3)
character(2)::word
u=27
a='--'

read(u,'(a)',iostat=ios)a(len(word))
if(ios/=0)stop 1
if(a(1)/='--'.or.a(2)/='xy'.or.a(3)/='--')stop 2
print '(a)',a(2)
end program

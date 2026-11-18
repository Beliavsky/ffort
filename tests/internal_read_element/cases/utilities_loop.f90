program p
implicit none
character(20)::lines(3)
integer::n,i,ios
character(20)::word
lines=[character(20)::"alpha rest","beta rest","gamma rest"]
do i=1,3
read(lines(i),*) word
if (i==1.and.trim(word)/="alpha") stop 1
if (i==2.and.trim(word)/="beta") stop 2
if (i==3.and.trim(word)/="gamma") stop 3
end do
print '(a)', "OK"
end program

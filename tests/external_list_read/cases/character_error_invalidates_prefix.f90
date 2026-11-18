program p
implicit none
integer::u
character(4)::word
integer::a,s
u=27
word="old"
read(u,*,iostat=s)word,a
print *,word
end program

program t
implicit none
character(5)::s
logical::v(5)
integer::i
s='abaca'
forall(i=1:5) v(i)=s(i:i)=='a'
print *,count(v)
end program

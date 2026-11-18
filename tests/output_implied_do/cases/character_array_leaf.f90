program main
implicit none
integer::i
character(2)::a(2)
a=["ab"," c"]
print '(8a)', "<",(a,i=1,2),">"
end program

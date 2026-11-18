program main
implicit none
integer::i
character(3)::x(4),y(3)
logical::a(4)
i=99
x=["cat","dog","cat","   "]
y=["dog","owl","   "]
a=[(all(y/=x(i)),i=1,size(x))]
print *,a,count(a),i
end program

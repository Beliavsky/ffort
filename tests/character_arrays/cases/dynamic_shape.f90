implicit none
character::a(3)="a",b(2)="b"
integer::n=3
print *,a(:n)//b
end

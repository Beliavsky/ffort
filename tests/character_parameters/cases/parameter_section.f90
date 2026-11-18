implicit none
character(*),parameter::a(3)=["ab","cd","ef"],b(2)=a(3:1:-2)
print '(a)',b//":"
end

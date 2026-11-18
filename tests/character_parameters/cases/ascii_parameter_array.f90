implicit none
character(*),parameter::a(3)=achar([65,66,67]),b(2,2)=char(reshape([65,66,67,68],[2,2]))
print '(a)',a,b
end

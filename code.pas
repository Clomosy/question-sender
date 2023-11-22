//Depremin büyüklüğünü ve süresini ölçen alete ne ad verilir?
//Termometre
//Tomograf
//Sismograf 
//Deprem ölçer

//Türkiye'nin en doğusundaki il hangisidir?
//Iğdır 
//Kars
//Van
//Hakkari

//Gülü ile meşhur olan ilimiz hangisidir?
//Isparta 
//Tekirdağ
//Lüleburgaz
//Kastamonu

//Türkiye'nin yüzölçümü en geniş şehri hangisidir?
//Konya 
//İstanbul
//Ankara
//Sivas

var
  MyForm:TclForm;
  questionChart : TClChart;
  simpleJSONStr, LineStr : String;
  
  LblDisplay:TclLabel;
  MyMQTT : TclMQTT;
  BtnSend:TclProButton;
  
  MemOptions,QuestionMemo,askMemo :TclMemo;
  RdoGrp:TClRadioGroup;
  
  myArrayInteger : TclArrayInteger;
  grafikCmboLayout:TClLayout;
  
  gSendButon :TClProButton;
  TypeCombo : TCLComboBox;
  myArrayString  : TclArrayString;
  UsersList,gidenKullanicilar:TclStringList;
  QMemList:TclJSonQuery;

  Procedure ReloadChartData;  //WİNDOWS ÜZERİNDE 
  Var i,y   :Integer;
    LineStr :String;
    
    begin
      simpleJSONStr:='';
      myArrayString := TclArrayString.Create;
      myArrayString.Add('clGreen');
      myArrayString.Add('clYellow');
      myArrayString.Add('clYellowGreen');
      myArrayString.Add('clBlue');
      myArrayString.Add('clAzure');
      myArrayString.Add('clTomato');
      myArrayString.Add('clPurple');
      myArrayString.Add('clPink');
      myArrayString.Add('clRed');
      myArrayString.Add('clGold');
      myArrayString.Add('clPeru');
      myArrayString.Add('clOrange');
      
      
      For i:=0 To MemOptions.Lines.Count-1 Do 
      Begin 
        myArrayString.GetItem(i);
        LineStr:=Clomosy.StringListItemString(MemOptions.Lines,i);
        LineStr:='{"OptionValue":"'+LineStr+'","OptionCount":"'+ IntToStr(myArrayInteger.GetItem(i))+'","color":"'+myArrayString.GetItem(i)+'"}';
        If simpleJSONStr='' Then 
        simpleJSONStr := simpleJSONStr + LineStr Else simpleJSONStr := simpleJSONStr + ',' + LineStr
      End;
       
      simpleJSONStr := '['+simpleJSONStr+']';
      questionChart.clLoadDataFromJSONStr(simpleJSONStr);
    End;
    
    
  Procedure MyMQTTPublishReceived;
  var 
    myStr,userGUID,userReply:String;
    i,j: Integer;
    varCntl,receivedUser : Boolean;
    
    begin
      varCntl := False;
      receivedUser := False;
      If Not MyMQTT.ReceivedAlright Then Exit;
      If Clomosy.PlatformIsMobile then
      begin
        for j := 0 to UsersList.Count - 1 do
        begin
          if Clomosy.StringListItemString(gidenKullanicilar,j) = userGUID then
          begin
            receivedUser := True;
          end;
        end;
        if receivedUser = False then
        begin
          MyStr := MyMQTT.ReceivedMessage;
          IF POS(';',MyStr)=0 Then  Exit; 
          
          If askMemo.Text = clGetStringTo(MyStr,';') then
          begin
          Exit;
          
          end else
          begin
            //uygulamayı sonradan acanlar için soru gönder butonuna tekrar basılması yeterli olur ancak bu arada önce açıp, 
            //bu soruya cevap veren tekrar cevap verememesi için soru değişti mi kontrol edilir.
            RdoGrp.Enabled := True;
            RdoGrp.ItemIndex := -1;
            
            RdoGrp.Title.Text := clGetStringTo(MyStr,';');//SORU
            RdoGrp.Items.Text := clGetStringAfter(MyStr,';');//SECENEKLER
            
            askMemo.Text := RdoGrp.Title.Text;
            RdoGrp.Title.Text := '';      
            
            BtnSend.Enabled := RdoGrp.Items.Text<>'';
            BtnSend.Text := 'Gönder';
            IF BtnSend.Enabled Then
              LblDisplay.Text := 'Seçiminizi Yapıp Göndere Basınız';
          end;
        end; 
      End Else 
      Begin //windows exe tarafında veri geldiğinde
        MyStr := MyMQTT.ReceivedMessage; 
        IF POS(';',MyStr)>0 Then   Exit;
        
        userGUID := clGetStringTo(MyStr,'|');
        userReply := clGetStringAfter(MyStr,'|');
        
        try
          for i := 0 to UsersList.Count - 1 do
          begin
            if Clomosy.StringListItemString(UsersList,i) = userGUID then
            begin
              varCntl := True;
              break;
            end;
          end;
          if varCntl = False then
          begin
            UsersList.Add(userGUID);
             myArrayInteger.SetItem(StrToInt(userReply),myArrayInteger.GetItem(StrToInt(userReply)) + 1); 
            ReloadChartData;
          end;
        except
          ShowMessage('17-Exception Class: '+LastExceptionClassName+' Exception Message: '+LastExceptionMessage);
        end;
      End;
    End;  
   
  Procedure BtnSendClick;
  Var
  i,j: Integer;
  mobilVarCntl : Boolean;
  begin
      mobilVarCntl := False;
      If Clomosy.PlatformIsMobile then
      begin
          IF RdoGrp.ItemIndex>-1 Then
          Begin
            RdoGrp.Enabled := False;
            BtnSend.Enabled := False;
            MyMQTT.Send(Clomosy.AppUserGUID+'|'+IntToStr(RdoGrp.ItemIndex));
            LblDisplay.Text := 'Yeni Soru Bekleniyor';
            BtnSend.Text := 'Seçiminiz Gönderildi';
            
          end Else ShowMessage('Lütfen Bir Seçim Yapınız!');
      End Else
      Begin//windows exe tarafında yapılan işlemler
       
         If (Trim(QuestionMemo.Text)<>'') and (Trim(MemOptions.Text)<>'') Then
         Begin
             MemOptions.Text := Trim(MemOptions.Text);
            
             If questionChart.ChartItemText <> QuestionMemo.Text Then 
             Begin
               myArrayInteger.RemoveAll;//diziyi sıfırla
               UsersList.Clear;
               questionChart.ChartItemText := QuestionMemo.Text;
               For i:=0 To MemOptions.Lines.Count Do myArrayInteger.Add(0);//yeni secenek sayısı kadar diziye eleman oluştur
               ReloadChartData;
               MyMQTT.Send(QuestionMemo.Text + ';' + MemOptions.Text);//soru ve secenekler arasında ";" ayracı ile gönderilir
             End else
             begin
              
              with QMemList do
             begin
               if Found then
               begin
                 First;
                 while not EOF do
                 begin
                    
                   for j := 0 to gidenKullanicilar.Count - 1 do
                  begin
                    mobilVarCntl := False;
                    if Clomosy.StringListItemString(gidenKullanicilar,j) = FieldByName('Member_GUID').AsString then
                    begin
                      mobilVarCntl := True;
                      gidenKullanicilar.Add(FieldByName('Member_GUID').AsString);
                      break;
                    end;
                  end;
                   if mobilVarCntl = false then
                   begin
                    MyMQTT.Send(QuestionMemo.Text + ';' + MemOptions.Text);//soru ve secenekler arasında ";" ayracı ile gönderilir
                    break;
                    end;
                   Next;
                 end;
               end;
             end;
            end;
         End Else ShowMessage('Soru ve Seçenekler olmalı!');
      End;
  End;
  
  
Procedure TypeGrapic;
var 
  str : String;
  I,grapic : Integer;
Begin
  
    str := TypeCombo.GetValueIndex(TypeCombo.ItemIndex);
    grapic := StrToInt(str);
    myArrayString := TclArrayString.Create;
    
    //myArrayString('clGreen','clRed','clYellow','clBlue','clYellowGreen','clAzure','clTomato','clPurple','clPink','clGold','clPeru','clOrange');
    myArrayString.Add('clGreen');
    myArrayString.Add('clYellow');
    myArrayString.Add('clYellowGreen');
    myArrayString.Add('clBlue');
    myArrayString.Add('clAzure');
    myArrayString.Add('clTomato');
    myArrayString.Add('clPurple');
    myArrayString.Add('clPink');
    myArrayString.Add('clRed');
    myArrayString.Add('clGold');
    myArrayString.Add('clPeru');
    myArrayString.Add('clOrange');
    
    
    For i:=0 To MemOptions.Lines.Count-1 Do 
    Begin 
        myArrayString.GetItem(i);
        LineStr:=Clomosy.StringListItemString(MemOptions.Lines,i);
        LineStr:='{"OptionValue":"'+LineStr+'","OptionCount":"'+ IntToStr(myArrayInteger.GetItem(i))+'","color":"'+myArrayString.GetItem(i)+'"}';
        
        if grapic = 1 then 
        begin
          questionChart.Charttype := clCBar;
          questionChart.clLoadDataFromJSONStr(simpleJSONStr);
        end;
        if grapic = 2 then
        begin
          questionChart.Charttype := clCLine;
          questionChart.clLoadDataFromJSONStr(simpleJSONStr);
        end;
        if grapic = 3 then
        begin
          questionChart.Charttype := clCPie;
          questionChart.clLoadDataFromJSONStr(simpleJSONStr);
        end;
    End;
  
    
End;
    
begin 
  MyForm := TclForm.Create(Self);
  UsersList := Clomosy.StringListNew;
  gidenKullanicilar :=  Clomosy.StringListNew;
  QMemList := Clomosy.DBCloudQueryWith(ftMembers,'','ISNULL(PMembers.Rec_Deleted,0)=0 ORDER BY NEWID()');
  LblDisplay:= MyForm.AddNewLabel(MyForm,'LblDisplay','--');
  LblDisplay.Visible := False;
  
  //GONDER BUTONU İKİ PLATFORMDA ÇIKIYOR
  BtnSend:= MyForm.AddNewProButton(MyForm,'BtnSend','Gönder');
  MyForm.AddNewEvent(BtnSend,tbeOnClick,'BtnSendClick');

   askMemo := MyForm.AddNewMemo(MyForm,'askMemo','');
   askMemo.TextSettings.WordWrap := True;
   askMemo.Visible := False;

  RdoGrp := MyForm.AddNewRadioGroup(MyForm,'RdoGrp','⌛');  
  RdoGrp.Visible := False;
  RdoGrp.Align := alTop;

  MyMQTT := MyForm.AddNewMQTTConnection(MyForm,'MyMQTT');
  MyForm.AddNewEvent(MyMQTT,tbeOnMQTTPublishReceived,'MyMQTTPublishReceived');
  MyMQTT.Channel := 'OnlineQuiz';//project guid + channel
  MyMQTT.Connect;
  
  If Clomosy.PlatformIsMobile then //MOBİL EKRANI
  Begin
    LblDisplay.Text := 'İçerik Bekleniyor...';
    LblDisplay.Align := almostTop;
    LblDisplay.Visible := True;
    LblDisplay.Height := LblDisplay.Height*4;

    askMemo.Align := alTop;
    askMemo.Text :='Soru...';
    askMemo.Visible := True;
    askMemo.Height := askMemo.Height*3;
    askMemo.ReadOnly := True;
    
    RdoGrp.Visible := True;
    RdoGrp.Align := alClient;
    
    BtnSend.Align := alTop;
    BtnSend.Align := alBottom;
    BtnSend.Height := BtnSend.Height*2;
    BtnSend.Enabled := False;
  
  End Else 
  Begin     //WİNDOWS EKRANI
    myArrayInteger := TClArrayInteger.Create;
    
    QuestionMemo:= MyForm.AddNewMemo(MyForm,'QuestionMemo','Sorunuzu girebilirsiniz...');
    QuestionMemo.Align := alTop;
    QuestionMemo.WordWrap := True;
    QuestionMemo.Height := QuestionMemo.Height;

    MemOptions:= MyForm.AddNewMemo(MyForm,'MemOptions','Seçenekleri girebilirsiniz..');
    MemOptions.Align := alBottom;
    MemOptions.Align := alTop;
    MemOptions.Height := MemOptions.Height*4;
    BtnSend.Align := alTop;
   
    questionChart := MyForm.AddNewChart(MyForm,'questionChart','Title');
    simpleJSONStr := '[{ "OptionValue": "Value1","OptionCount": 0,"color":"clOrange"}]';
    questionChart.Align := alClient;
    questionChart.Margins.Left := 10;
    questionChart.Margins.Right := 10;
    questionChart.Charttype := clCBar;
    questionChart.XAxisText :='OptionValue';
    questionChart.ChartItemText := 'Soru Cevap';
    questionChart.ChartItemsValue := 'OptionCount';
    questionChart.ChartTitle := 'Kim Milyoner Olmak İster Formatında Seyirci Cevapları Demo Uygulaması';
    questionChart.Xaxis.AutoSize :=False;
    questionChart.Yaxis.AutoSize :=False;
    questionChart.clLoadDataFromJSONStr(simpleJSONStr);
    questionChart.SeriesMargins.Top := 20; 

  
    grafikCmboLayout := MyForm.AddNewLayout(MyForm,'grafikCmboLayout');
    grafikCmboLayout.Align:=albottom;
    grafikCmboLayout.Height := 50;
  
    TypeCombo := MyForm.AddNewComboBox(grafikCmboLayout,'testCombo');
    TypeCombo.Align := alcenter;
    TypeCombo.Width := 300;
    TypeCombo.Margins.Bottom:=6;
    TypeCombo.Margins.Left :=50;
    TypeCombo.Margins.Right :=10;
    
    TypeCombo.AddItem('Bar Grafiği','1');
    TypeCombo.AddItem('Çizgi Grafik','2');
    TypeCombo.AddItem('Pasta Grafiği','3');
    MyForm.AddNewEvent(TypeCombo,tbeOnChange,'TypeGrapic');
    
  End;
  
  
  MyForm.Run;

end;
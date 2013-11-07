require 'spec_helper'
require 'puppet/provider/xmlfile/lens'
require 'puppet/util/diff'

describe XmlLens do
  let(:testobject) { XmlLens }
  # Build out tests as we come up with comparisons to augeas
  before(:all) do
    # Initialize our content as the default activemq xml file as it
    # has most of the appropriate xml warts(and is why we wrote this).
    @content = <<-'EOT'
<beans
  xmlns="http://www.springframework.org/schema/beans"
  xmlns:amq="http://activemq.apache.org/schema/core"
  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
  xsi:schemaLocation="http://www.springframework.org/schema/beans http://www.springframework.org/schema/beans/spring-beans.xsd
  http://activemq.apache.org/schema/core http://activemq.apache.org/schema/core/activemq-core.xsd">

    <bean class="org.springframework.beans.factory.config.PropertyPlaceholderConfigurer">
        <property name="locations">
            <value>file:${activemq.conf}/credentials.properties</value>
        </property>
    </bean>

    <broker xmlns="http://activemq.apache.org/schema/core" brokerName="localhost" dataDirectory="${activemq.data}">
 
        <destinationPolicy>
            <policyMap>
              <policyEntries>
                <policyEntry topic=">" producerFlowControl="true">
                  <pendingMessageLimitStrategy>
                    <constantPendingMessageLimitStrategy limit="1000"/>
                  </pendingMessageLimitStrategy>
                </policyEntry>
                <policyEntry queue=">" producerFlowControl="true" memoryLimit="1mb">
                </policyEntry>
              </policyEntries>
            </policyMap>
        </destinationPolicy>

        <managementContext>
            <managementContext createConnector="false"/>
        </managementContext>
 
        <persistenceAdapter>
            <kahaDB directory="${activemq.data}/kahadb"/>
        </persistenceAdapter>

          <systemUsage>
            <systemUsage>
                <memoryUsage>
                    <memoryUsage limit="64 mb"/>
                </memoryUsage>
                <storeUsage>
                    <storeUsage limit="100 gb"/>
                </storeUsage>
                <tempUsage>
                    <tempUsage limit="50 gb"/>
                </tempUsage>
            </systemUsage>
        </systemUsage>
 
        <transportConnectors>
            <!-- DOS protection, limit concurrent connections to 1000 and frame size to 100MB -->
            <transportConnector name="openwire" uri="tcp://0.0.0.0:61616?maximumConnections=1000&amp;wireFormat.maxFrameSize=104857600"/>
            <transportConnector name="amqp" uri="amqp://0.0.0.0:5672?maximumConnections=1000&amp;wireFormat.maxFrameSize=104857600"/>
        </transportConnectors>

        <shutdownHooks>
            <bean xmlns="http://www.springframework.org/schema/beans" class="org.apache.activemq.hooks.SpringContextHook" />
        </shutdownHooks>
 
    </broker>

    <import resource="jetty.xml"/>
 
</beans>
    EOT
    @rexml = REXML::Document.new(@content)
  end
  
  after(:all) do
    # Delete the tempfile
    # File.unlink("/tmp/xmllens_test.tmp")
  end
  
  describe :add do
  end
  
  describe :set do
    it "should test things" do
      Puppet::Util::Storage.stubs(:store)
      
      changes = "beans/broker/plugins/authorizationPlugin/map/authorizationMap/authorizationEntries/authorizationEntry[last()+1]/#attribute/queue \"test\""
      aug_changes = [ "set #{changes}" ]
      xmllens_changes = [ "set /#{changes}" ]
      
      puppet_test = File.open('/tmp/puppet', 'w+')
      @rexml.write(puppet_test)
      puppet_test.close
      
      resource = Puppet::Type.type(:augeas).new(
         :name => 'test',
         :incl => '/tmp/puppet',
         :lens => 'Xml.lns',
         :changes => aug_changes,
      )

      catalog = Puppet::Resource::Catalog.new
      catalog.add_resource resource

      catalog.apply
      
      test = XmlLens.new(@rexml, xmllens_changes, nil)
      #test.evaluate.write($stdout)
      
      #puts File.read(puppet_test)
      
      # Need to do a comparison, maybe XPath?
    end
  end
  
  describe :rm do
    it "should create identical output to augeas"
  end
end
